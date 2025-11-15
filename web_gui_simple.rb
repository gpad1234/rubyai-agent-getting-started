#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'sinatra'
require 'json'
require 'fileutils'
require 'time'

require_relative 'lib/concurrent_agent'
require_relative 'lib/background_agent'

# Configure Sinatra
set :port, 3000
set :bind, '0.0.0.0'
set :sessions, true
set :public_folder, File.expand_path('public', __dir__)

# Message logger class
class MessageLogger
  def initialize(log_dir = 'logs')
    @log_dir = log_dir
    @messages = []
    FileUtils.mkdir_p(@log_dir) unless Dir.exist?(@log_dir)
    load_messages
  end

  def log_message(type, sender, message, metadata = {})
    entry = {
      timestamp: Time.now.iso8601,
      type: type,
      sender: sender,
      message: message,
      metadata: metadata
    }
    @messages << entry
    write_to_file(entry)
    entry
  end

  def get_messages(limit = 100)
    @messages.last(limit)
  end

  def clear_messages
    @messages = []
    Dir.glob(File.join(@log_dir, '*.log')).each { |f| File.delete(f) }
  end

  private

  def load_messages
    Dir.glob(File.join(@log_dir, '*.log')).each do |file|
      File.readlines(file).each do |line|
        @messages << JSON.parse(line, symbolize_names: true)
      end
    end
  rescue => e
    warn "Failed to load messages: #{e.message}"
  end

  def write_to_file(entry)
    log_file = File.join(@log_dir, "messages_#{Time.now.strftime('%Y%m%d')}.log")
    File.open(log_file, 'a') do |f|
      f.puts entry.to_json
    end
  end
end

# Global initialization
LOG_DIR = 'logs'
FileUtils.mkdir_p(LOG_DIR)
FileUtils.mkdir_p('public')

$logger = MessageLogger.new(LOG_DIR)
$client = nil

begin
  $client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])
rescue => e
  warn "Warning: Failed to initialize Anthropic client: #{e.message}"
end

# Boot Celluloid
begin
  require 'celluloid'
  Celluloid.boot
rescue => e
  # Celluloid not available or already booted
end

# Routes
get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

post '/api/send_message' do
  content_type :json
  
  begin
    data = JSON.parse(request.body.read)
    user_message = data['message']
    agent_type = data['agent_type'] || 'concurrent'

    unless $logger
      raise 'Logger not initialized'
    end

    $logger.log_message('user_message', 'User', user_message, { agent: agent_type })

    unless $client
      raise 'Anthropic client not initialized. Check ANTHROPIC_API_KEY'
    end

    response = case agent_type
               when 'concurrent'
                 agent = ConcurrentAgent.new($client)
                 agent.execute_with_promises(user_message)
               when 'background'
                 agent = BackgroundAgent.new($client)
                 agent.perform('generate_content', { 'prompt' => user_message, 'context' => '' })
               else
                 'Unknown agent type'
               end

    $logger.log_message('ai_response', "#{agent_type} Agent", response, { user_message: user_message })

    { success: true, response: response }.to_json
  rescue => e
    if $logger
      $logger.log_message('error', 'System', e.message, { error_class: e.class })
    end
    { success: false, error: e.message }.to_json
  end
end

get '/api/messages' do
  content_type :json
  
  begin
    limit = params['limit']&.to_i || 100
    if $logger
      $logger.get_messages(limit).to_json
    else
      [].to_json
    end
  rescue => e
    { error: e.message }.to_json
  end
end

get '/api/clear_messages' do
  content_type :json
  
  begin
    if $logger
      $logger.clear_messages
    end
    { success: true, message: 'Messages cleared' }.to_json
  rescue => e
    { success: false, error: e.message }.to_json
  end
end

get '/api/logs' do
  content_type :json
  
  begin
    log_files = Dir.glob(File.join(LOG_DIR, '*.log')).sort.reverse
    
    logs = log_files.map do |file|
      {
        filename: File.basename(file),
        size: File.size(file),
        lines: File.readlines(file).count,
        modified: File.mtime(file).iso8601
      }
    end

    logs.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

get '/api/log/:filename' do
  content_type :json
  
  begin
    filename = params['filename']
    filepath = File.join(LOG_DIR, filename)

    unless File.exist?(filepath) && filepath.start_with?(File.expand_path(LOG_DIR))
      return { error: 'File not found' }.to_json
    end

    entries = []
    File.readlines(filepath).each do |line|
      entries << JSON.parse(line, symbolize_names: true)
    end

    entries.to_json
  rescue => e
    { error: e.message }.to_json
  end
end

get '/health' do
  content_type :json
  { status: 'ok', timestamp: Time.now.iso8601 }.to_json
end

puts "\n🚀 Ruby AI Agents Web GUI Starting..."
puts "📍 Server running at http://localhost:3000"
puts "💬 Open your browser and start chatting!"
puts "📁 Logs stored in: ./logs/"
puts "⚠️  Press Ctrl+C to stop the server\n"
