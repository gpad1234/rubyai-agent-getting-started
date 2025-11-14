# frozen_string_literal: true

require 'anthropic'

# Background job agent (Sidekiq/Resque style)
# This is a worker class that can be used with Sidekiq or Resque
class BackgroundAgent
  # For Sidekiq
  # include Sidekiq::Worker
  # sidekiq_options retry: 3, queue: 'ai_tasks'

  def initialize(client = nil)
    @client = client || Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])
  end

  # Main perform method (called by background job processors)
  def perform(task_type, payload)
    case task_type
    when 'analyze_text'
      analyze_text(payload['text'])
    when 'generate_content'
      generate_content(payload['prompt'], payload['context'])
    when 'summarize'
      summarize(payload['text'])
    when 'batch_process'
      batch_process(payload['items'])
    else
      raise "Unknown task type: #{task_type}"
    end
  end

  # Analyze text using Claude
  def analyze_text(text)
    puts "\n🔍 Analyzing text (#{text.length} characters)..."
    
    response = @client.messages(
      parameters: {
        model: 'claude-3-5-haiku-20241022',
        max_tokens: 800,
        messages: [{
          role: 'user',
          content: "Analyze the following text and provide insights:\n\n#{text}"
        }]
      }
    )
    
    result = response.dig('content', 0, 'text')
    log_result('analyze_text', result)
    result
  end

  # Generate content based on prompt
  def generate_content(prompt, context = {})
    puts "\n✍️  Generating content for: #{prompt[0..50]}..."
    
    full_prompt = context.empty? ? prompt : "Context: #{context}\n\nTask: #{prompt}"
    
    response = @client.messages(
      parameters: {
        model: 'claude-3-5-haiku-20241022',
        max_tokens: 1000,
        messages: [{ role: 'user', content: full_prompt }]
      }
    )
    
    result = response.dig('content', 0, 'text')
    log_result('generate_content', result)
    result
  end

  # Summarize text
  def summarize(text)
    puts "\n📝 Summarizing text..."
    
    response = @client.messages(
      parameters: {
        model: 'claude-3-5-haiku-20241022',
        max_tokens: 500,
        messages: [{
          role: 'user',
          content: "Provide a concise summary of:\n\n#{text}"
        }]
      }
    )
    
    result = response.dig('content', 0, 'text')
    log_result('summarize', result)
    result
  end

  # Process multiple items
  def batch_process(items)
    puts "\n📦 Batch processing #{items.size} items..."
    
    results = items.map.with_index do |item, index|
      puts "  Processing item #{index + 1}/#{items.size}..."
      analyze_text(item)
    end
    
    puts "✅ Batch processing complete!"
    results
  end

  private

  def log_result(task_type, result)
    # In production, this would log to a database or file
    puts "✅ Task '#{task_type}' completed. Result length: #{result.length} characters"
  end
end

# Job scheduler for background tasks
class BackgroundJobScheduler
  def initialize(agent)
    @agent = agent
    @jobs = []
  end

  # Schedule a job
  def schedule_job(task_type, payload, delay = 0)
    job = {
      id: generate_job_id,
      task_type: task_type,
      payload: payload,
      scheduled_at: Time.now + delay,
      status: 'pending'
    }
    
    @jobs << job
    puts "📅 Job #{job[:id]} scheduled for #{job[:scheduled_at]}"
    job[:id]
  end

  # Execute scheduled jobs
  def execute_pending_jobs
    pending = @jobs.select { |j| j[:status] == 'pending' && j[:scheduled_at] <= Time.now }
    
    puts "\n🚀 Executing #{pending.size} pending jobs..."
    
    pending.each do |job|
      begin
        job[:status] = 'running'
        result = @agent.perform(job[:task_type], job[:payload])
        job[:status] = 'completed'
        job[:result] = result
        job[:completed_at] = Time.now
        puts "✅ Job #{job[:id]} completed"
      rescue => e
        job[:status] = 'failed'
        job[:error] = e.message
        puts "❌ Job #{job[:id]} failed: #{e.message}"
      end
    end
  end

  # Get job status
  def job_status(job_id)
    @jobs.find { |j| j[:id] == job_id }
  end

  # List all jobs
  def list_jobs
    @jobs
  end

  private

  def generate_job_id
    "job_#{Time.now.to_i}_#{rand(1000)}"
  end
end
