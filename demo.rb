#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'anthropic'

require_relative 'lib/concurrent_agent'
require_relative 'lib/celluloid_agent'
require_relative 'lib/background_agent'
require_relative 'lib/web_automation_agent'

# Boot Celluloid actor system
begin
  Celluloid.boot
rescue => e
  # Celluloid may already be booted or unavailable
end

# Initialize Claude client
client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

def print_header(title)
  puts "\n" + "=" * 60
  puts "  #{title}"
  puts "=" * 60 + "\n"
end

def demo_menu
  puts "\n📋 Ruby AI Agents Demo Menu"
  puts "1. Concurrent Agent (Parallel Processing)"
  puts "2. Celluloid Agent (Actor Model)"
  puts "3. Background Agent (Job Processing)"
  puts "4. Web Automation Agent (Scraping)"
  puts "5. Run All Demos"
  puts "6. Exit"
  print "\nSelect an option (1-6): "
end

def run_concurrent_demo(client)
  print_header("🔄 CONCURRENT AGENT DEMO")
  
  agent = ConcurrentAgent.new(client)
  
  tasks = [
    { name: "Ruby Info", prompt: "Explain Ruby in one sentence" },
    { name: "AI Info", prompt: "What is an AI agent in one sentence?" },
    { name: "Concurrency", prompt: "Define concurrent programming in one sentence" }
  ]
  
  results = agent.execute_parallel_tasks(tasks)
  
  puts "\n✅ Completed #{results.size} parallel tasks"
  results.each do |result|
    puts "\n📝 #{result[:task]}:"
    puts "   #{result[:response][0..100]}..."
  end
end

def run_celluloid_demo(client)
  print_header("🎭 CELLULOID AGENT DEMO")
  
  begin
    supervisor = AgentSupervisor.new(client, 2)
    
    tasks = [
      "What is the actor model?",
      "Explain message passing",
      "Benefits of actors"
    ]
    
    results = supervisor.distribute_work(tasks)
    
    puts "\n✅ Processed #{results.size} messages through actor pool"
    
    status = supervisor.status
    puts "\n📊 Pool Status: #{status[:pool_size]} agents"
  rescue => e
    puts "\n⚠️  Celluloid demo error: #{e.message}"
    puts "Tip: Celluloid requires proper actor system initialization"
  end
end

def run_background_demo(client)
  print_header("📦 BACKGROUND AGENT DEMO")
  
  agent = BackgroundAgent.new(client)
  scheduler = BackgroundJobScheduler.new(agent)
  
  # Schedule jobs
  scheduler.schedule_job('analyze_text', { 
    'text' => 'Ruby is a dynamic programming language' 
  })
  scheduler.schedule_job('summarize', { 
    'text' => 'Background jobs allow you to process tasks asynchronously, improving application responsiveness and user experience.' 
  })
  
  puts "\n⏳ Executing scheduled jobs..."
  sleep 1
  scheduler.execute_pending_jobs
  
  completed = scheduler.list_jobs.count { |j| j[:status] == 'completed' }
  puts "\n✅ Completed #{completed} background jobs"
end

def run_web_automation_demo(client)
  print_header("🌐 WEB AUTOMATION AGENT DEMO")
  
  agent = WebAutomationAgent.new(client)
  
  begin
    puts "Attempting to scrape example.com..."
    result = agent.scrape_and_analyze(
      'https://example.com',
      'Describe this webpage briefly'
    )
    
    puts "\n✅ Successfully scraped and analyzed webpage"
  rescue => e
    puts "\n⚠️  Demo completed (network dependent): #{e.message}"
  end
end

def run_all_demos(client)
  run_concurrent_demo(client)
  sleep 1
  run_celluloid_demo(client)
  sleep 1
  run_background_demo(client)
  sleep 1
  run_web_automation_demo(client)
  
  print_header("🎉 ALL DEMOS COMPLETED")
end

# Main program
if __FILE__ == $PROGRAM_NAME
  puts "
  ╔═══════════════════════════════════════╗
  ║   Ruby AI Agents with Claude          ║
  ║   Powered by Anthropic API            ║
  ╚═══════════════════════════════════════╝
  "

  loop do
    demo_menu
    choice = gets&.chomp || ''
    
    case choice
    when '1'
      run_concurrent_demo(client)
    when '2'
      run_celluloid_demo(client)
    when '3'
      run_background_demo(client)
    when '4'
      run_web_automation_demo(client)
    when '5'
      run_all_demos(client)
    when '6'
      puts "\n👋 Goodbye!"
      break
    else
      puts "\n❌ Invalid option. Please select 1-6."
    end
    
    puts "\n" + "-" * 60
  end
end
