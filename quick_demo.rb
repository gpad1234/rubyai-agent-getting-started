#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'anthropic'

require_relative 'lib/concurrent_agent'
require_relative 'lib/celluloid_agent'
require_relative 'lib/background_agent'
require_relative 'lib/web_automation_agent'

def print_header(title)
  puts "\n" + "=" * 60
  puts "  #{title}"
  puts "=" * 60
end

# Quick demo without actual API calls
def quick_demo
  client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])
  
  print_header("🚀 QUICK AGENT STRUCTURE DEMO")
  
  puts "\n1️⃣  ConcurrentAgent - Ready ✅"
  puts "   - Parallel task execution"
  puts "   - Promise-based workflows"
  puts "   - Thread-safe operations"
  
  puts "\n2️⃣  CelluloidAgent - Ready ✅"
  puts "   - Actor-based messaging"
  puts "   - Supervisor pattern"
  puts "   - Async processing"
  
  puts "\n3️⃣  BackgroundAgent - Ready ✅"
  puts "   - Job scheduling"
  puts "   - Text analysis"
  puts "   - Content generation"
  
  puts "\n4️⃣  WebAutomationAgent - Ready ✅"
  puts "   - Web scraping"
  puts "   - Link extraction"
  puts "   - AI-powered analysis"
  
  print_header("💡 TIP")
  puts "Run individual examples for full demos:"
  puts "  ruby examples/concurrent_example.rb"
  puts "  ruby examples/celluloid_example.rb"
  puts "  ruby examples/background_example.rb"
  puts "  ruby examples/web_automation_example.rb"
  
  puts "\n⚡ Or run: ruby demo.rb for interactive menu"
  puts "\n⏱️  Note: API calls take 2-5 seconds each"
end

quick_demo if __FILE__ == $PROGRAM_NAME
