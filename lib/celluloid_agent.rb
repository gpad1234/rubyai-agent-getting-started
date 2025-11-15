# frozen_string_literal: true

require 'celluloid'
require 'anthropic'

# Actor-based agent using Celluloid for message-passing concurrency
class CelluloidAgent
  include Celluloid

  def initialize(client_or_pool_size = nil)
    # Support both client object and pool size for backward compatibility
    if client_or_pool_size.is_a?(Anthropic::Client)
      @client = client_or_pool_size
    elsif client_or_pool_size.is_a?(Integer)
      # If given a number, it's treated as pool size - we need client from caller
      warn "CelluloidAgent initialized with pool size #{client_or_pool_size}. Use CelluloidAgent.new(client) instead."
      @client = nil
    else
      @client = client_or_pool_size
    end
    @conversation_history = []
  end

  # Process a single message asynchronously
  def process_message(message, context = {})
    puts "\n🎭 Actor processing message: #{message[0..50]}..."
    
    unless @client
      raise "Celluloid agent not initialized with a client. Use CelluloidAgent.new(client)"
    end
    
    response = @client.messages(
      parameters: {
        model: 'claude-3-5-haiku-20241022',
        max_tokens: 500,
        messages: [{ role: 'user', content: message }]
      }
    )
    
    result = response.dig('content', 0, 'text')
    
    # Store in conversation history
    @conversation_history << {
      timestamp: Time.now,
      message: message,
      response: result,
      context: context
    }
    
    puts "✅ Actor completed processing"
    result
  end

  # Get conversation history
  def get_history
    @conversation_history
  end

  # Clear history
  def clear_history
    @conversation_history.clear
    puts "🗑️  Conversation history cleared"
  end

  # Process multiple messages in sequence
  def process_batch(messages)
    puts "\n📦 Actor processing batch of #{messages.size} messages..."
    messages.map { |msg| process_message(msg) }
  end
end

# Supervisor actor to manage multiple agents
class AgentSupervisor
  include Celluloid

  def initialize(client, pool_size = 3)
    @client = client
    @agent_pool = pool_size.times.map { CelluloidAgent.new(@client) }
    puts "👥 Supervisor initialized with #{pool_size} agents"
  end

  # Distribute work across agent pool
  def distribute_work(tasks)
    puts "\n🎯 Supervisor distributing #{tasks.size} tasks across agent pool..."
    
    futures = tasks.map.with_index do |task, index|
      agent = @agent_pool[index % @agent_pool.size]
      Celluloid::Future.new { agent.process_message(task, worker: index % @agent_pool.size) }
    end

    futures.map(&:value)
  end

  # Get status of all agents
  def status
    {
      pool_size: @agent_pool.size,
      agents: @agent_pool.map.with_index do |agent, i|
        { id: i, history_count: agent.get_history.size }
      end
    }
  end
end
