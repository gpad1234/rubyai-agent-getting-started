#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'anthropic'
require 'dotenv/load'

# Initialize the Anthropic client
client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

def chat_with_claude(client, user_message)
  puts "\n🤖 Sending message to Claude..."
  
  response = client.messages(
    parameters: {
      model: 'claude-3-5-haiku-20241022',
      max_tokens: 1024,
      messages: [
        { role: 'user', content: user_message }
      ]
    }
  )
  
  assistant_message = response.dig('content', 0, 'text')
  puts "\n💬 Claude's response:"
  puts assistant_message
  puts "\n"
  
  assistant_message
end

# Example usage
if __FILE__ == $PROGRAM_NAME
  puts "=== Ruby AI with Claude ==="
  
  # Simple conversation
  chat_with_claude(client, "Hello! Can you explain what you are in one sentence?")
  
  # Ask a question
  chat_with_claude(client, "What are the top 3 features of Ruby programming language?")
  
  # Interactive mode
  puts "Enter 'quit' to exit"
  loop do
    print "\nYou: "
    input = gets.chomp
    break if input.downcase == 'quit'
    
    chat_with_claude(client, input)
  end
end
