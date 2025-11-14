#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require_relative '../lib/background_agent'

puts "=== Background Agent Example ==="

# Initialize agent
agent = BackgroundAgent.new

# Example 1: Analyze text
puts "\n--- Text Analysis Example ---"
sample_text = "Ruby is a dynamic, open source programming language with a focus on simplicity and productivity. It has an elegant syntax that is natural to read and easy to write."
agent.analyze_text(sample_text)

# Example 2: Generate content
puts "\n--- Content Generation Example ---"
agent.generate_content(
  "Write a short poem about Ruby programming",
  { style: 'haiku', theme: 'programming' }
)

# Example 3: Summarize
puts "\n--- Summarization Example ---"
long_text = "Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any system that perceives its environment and takes actions that maximize its chance of achieving its goals. The term artificial intelligence had previously been used to describe machines that mimic and display human cognitive skills that are associated with the human mind, such as learning and problem-solving."
agent.summarize(long_text)

# Example 4: Job scheduling
puts "\n--- Job Scheduling Example ---"
scheduler = BackgroundJobScheduler.new(agent)

# Schedule jobs
job1 = scheduler.schedule_job('analyze_text', { 'text' => 'Quick analysis test' })
job2 = scheduler.schedule_job('summarize', { 'text' => long_text }, 2)
job3 = scheduler.schedule_job('generate_content', { 
  'prompt' => 'List 3 benefits of background jobs',
  'context' => {}
}, 1)

puts "\n📋 Jobs scheduled: #{scheduler.list_jobs.size}"

# Execute jobs
puts "\n⏳ Waiting for scheduled time..."
sleep 3

scheduler.execute_pending_jobs

# Check status
puts "\n📊 Job Status:"
scheduler.list_jobs.each do |job|
  puts "  #{job[:id]}: #{job[:status]}"
end
