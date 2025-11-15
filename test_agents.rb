#!/usr/bin/env ruby
require 'bundler/setup'
require 'dotenv/load'

require_relative 'lib/concurrent_agent'
require_relative 'lib/background_agent'
require_relative 'lib/celluloid_agent'
require_relative 'lib/web_automation_agent'

client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

puts "\n🧪 Testing All 4 Agents...\n"

# Test 1: Concurrent Agent
begin
  puts "1️⃣  Testing ConcurrentAgent..."
  agent = ConcurrentAgent.new(client)
  result = agent.execute_with_promises("What is Ruby?")
  puts "   ✅ ConcurrentAgent works! Response: #{result[0..50]}..."
rescue => e
  puts "   ❌ ConcurrentAgent failed: #{e.message}"
end

# Test 2: Background Agent
begin
  puts "\n2️⃣  Testing BackgroundAgent..."
  agent = BackgroundAgent.new(client)
  result = agent.perform('generate_content', { 'prompt' => 'What is Python?', 'context' => '' })
  puts "   ✅ BackgroundAgent works! Response: #{result[0..50]}..."
rescue => e
  puts "   ❌ BackgroundAgent failed: #{e.message}"
end

# Test 3: Celluloid Agent
begin
  puts "\n3️⃣  Testing CelluloidAgent..."
  require 'celluloid'
  Celluloid.boot
  agent = CelluloidAgent.new(client)
  result = agent.process_message("What is Go?")
  puts "   ✅ CelluloidAgent works! Response: #{result[0..50]}..."
rescue => e
  puts "   ❌ CelluloidAgent failed: #{e.message}"
end

# Test 4: Web Automation Agent
begin
  puts "\n4️⃣  Testing WebAutomationAgent..."
  agent = WebAutomationAgent.new(client)
  result = agent.scrape_and_analyze("https://example.com", "What is this website about?")
  puts "   ✅ WebAutomationAgent works! Response: #{result[0..50]}..."
rescue => e
  puts "   ❌ WebAutomationAgent failed: #{e.message}"
end

puts "\n✨ Testing complete!\n"
