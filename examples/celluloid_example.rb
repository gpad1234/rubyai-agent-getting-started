#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require_relative '../lib/celluloid_agent'

# Boot Celluloid
Celluloid.boot

# Initialize Claude client
client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

puts "=== Celluloid Agent Example ==="

# Example 1: Single actor
puts "\n--- Single Actor Example ---"
actor = CelluloidAgent.new(client)
actor.async.process_message("What is the actor model in Ruby?")
sleep 2 # Give async call time to complete

# Example 2: Supervisor with agent pool
puts "\n--- Supervisor Example ---"
supervisor = AgentSupervisor.new(client, 3)

tasks = [
  "Explain Celluloid in Ruby",
  "What are actors in concurrent programming?",
  "How does message passing work?",
  "What is the benefit of the actor model?",
  "Explain supervisors in actor systems"
]

results = supervisor.distribute_work(tasks)
puts "\n✅ Received #{results.size} results from agent pool"

# Check status
status = supervisor.status
puts "\n📊 Supervisor Status:"
puts "  Pool size: #{status[:pool_size]}"
status[:agents].each do |agent_info|
  puts "  Agent #{agent_info[:id]}: #{agent_info[:history_count]} messages processed"
end
