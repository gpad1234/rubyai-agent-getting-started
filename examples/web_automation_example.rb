#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require_relative '../lib/web_automation_agent'

# Initialize Claude client
client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

# Create web automation agent
agent = WebAutomationAgent.new(client)

puts "=== Web Automation Agent Example ==="

# Example 1: Scrape and analyze a simple webpage
puts "\n--- Scraping Example ---"
begin
  agent.scrape_and_analyze(
    'https://example.com',
    'What is the main purpose of this webpage?'
  )
rescue => e
  puts "⚠️  Error: #{e.message}"
  puts "This is expected if network access is limited"
end

# Example 2: Extract links (using a public site)
puts "\n--- Link Extraction Example ---"
begin
  agent.extract_and_analyze_links('https://www.ruby-lang.org/', 5)
rescue => e
  puts "⚠️  Error: #{e.message}"
end

# Example 3: Search with CSS selector
puts "\n--- Element Search Example ---"
begin
  agent.search_and_extract(
    'https://example.com',
    'h1',
    'Analyze these headings'
  )
rescue => e
  puts "⚠️  Error: #{e.message}"
end

puts "\n✅ Web automation examples completed"
puts "💡 Tip: Web automation works best with public websites and stable internet connection"
