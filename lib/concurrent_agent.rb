# frozen_string_literal: true

require 'concurrent'
require 'anthropic'

# Agent using concurrent-ruby for parallel task execution
class ConcurrentAgent
  def initialize(client)
    @client = client
    @executor = Concurrent::FixedThreadPool.new(5)
  end

  # Execute multiple AI tasks concurrently
  def execute_parallel_tasks(tasks)
    puts "\n🔄 Executing #{tasks.size} tasks concurrently..."
    
    futures = tasks.map do |task|
      Concurrent::Future.execute(executor: @executor) do
        ask_claude(task[:prompt], task[:name])
      end
    end

    # Wait for all tasks to complete
    results = futures.map(&:value)
    
    puts "\n✅ All tasks completed!"
    results
  end

  # Execute tasks with promises
  def execute_with_promises(prompt)
    promise = Concurrent::Promise.execute do
      ask_claude(prompt, "Promise Task")
    end

    promise.then do |result|
      puts "\n✨ Promise fulfilled with result length: #{result.length} characters"
      result
    end.rescue do |error|
      puts "\n❌ Promise rejected: #{error.message}"
      nil
    end

    promise.wait.value
  end

  # Use atomic counter for task tracking
  def execute_with_tracking(prompts)
    counter = Concurrent::AtomicFixnum.new(0)
    total = prompts.size
    
    results = prompts.map do |prompt|
      Concurrent::Future.execute(executor: @executor) do
        result = ask_claude(prompt, "Task #{counter.increment}/#{total}")
        result
      end
    end

    results.map(&:value)
  end

  private

  def ask_claude(prompt, task_name)
    puts "\n📤 [#{task_name}] Sending: #{prompt[0..50]}..."
    
    response = @client.messages(
      parameters: {
        model: 'claude-3-5-haiku-20241022',
        max_tokens: 500,
        messages: [{ role: 'user', content: prompt }]
      }
    )
    
    result = response.dig('content', 0, 'text')
    puts "📥 [#{task_name}] Received response (#{result.length} chars)"
    
    { task: task_name, prompt: prompt, response: result }
  end

  def shutdown
    @executor.shutdown
    @executor.wait_for_termination
  end
end
