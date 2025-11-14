#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require_relative '../lib/concurrent_agent'

# Initialize Claude client
client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

# Create concurrent agent
agent = ConcurrentAgent.new(client)

puts "=== Concurrent Agent Example ==="

# Example 1: Parallel tasks
tasks = [
  { name: "Task 1", prompt: "What is Ruby programming language?" },
  { name: "Task 2", prompt: "Explain concurrency in Ruby" },
  { name: "Task 3", prompt: "What are the benefits of parallel processing?" }
]

results = agent.execute_parallel_tasks(tasks)
puts "\n📊 Received #{results.size} results from parallel execution"

# Example 2: Promises
puts "\n\n=== Promise Example ==="
agent.execute_with_promises("Explain the promise pattern in one sentence")

# Example 3: Tracked execution
puts "\n\n=== Tracked Execution Example ==="
prompts = [
  "What is an AI agent?",
  "How does Claude work?",
  "Explain async programming"
]

tracked_results = agent.execute_with_tracking(prompts)
puts "\n✅ Completed #{tracked_results.size} tracked tasks"
