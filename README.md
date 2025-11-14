# Ruby AI Agents with Claude

A comprehensive Ruby application demonstrating different types of AI agents using Claude API.

## Agent Types

### 1. **ConcurrentAgent** - Concurrent-ruby
Parallel task execution with futures, promises, and atomic operations.
- Execute multiple AI tasks concurrently
- Promise-based workflows
- Thread-safe task tracking

### 2. **CelluloidAgent** - Actor-based concurrency
Message-passing concurrency with actor model.
- Asynchronous message processing
- Agent pools with supervisors
- Conversation history management

### 3. **BackgroundAgent** - Background job processing
Resque/Sidekiq-style background task handling.
- Text analysis and summarization
- Content generation
- Job scheduling and tracking

### 4. **WebAutomationAgent** - Web automation
Mechanize-powered web scraping and interaction.
- Page scraping and analysis
- Link extraction
- Form automation with AI-generated data

## Setup

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Create a `.env` file with your Anthropic API key:
   ```bash
   cp .env.example .env
   ```

3. Add your API key to `.env`:
   ```
   ANTHROPIC_API_KEY=your_actual_api_key_here
   ```

## Usage

Run individual agent examples:

```bash
# Concurrent agent
ruby examples/concurrent_example.rb

# Celluloid actor agent
ruby examples/celluloid_example.rb

# Background job agent
ruby examples/background_example.rb

# Web automation agent
ruby examples/web_automation_example.rb
```

## Agent Features

### ConcurrentAgent
```ruby
agent = ConcurrentAgent.new(client)
tasks = [
  { name: "Task 1", prompt: "Question 1" },
  { name: "Task 2", prompt: "Question 2" }
]
results = agent.execute_parallel_tasks(tasks)
```

### CelluloidAgent
```ruby
supervisor = AgentSupervisor.new(client, 3)
results = supervisor.distribute_work(["Task 1", "Task 2", "Task 3"])
```

### BackgroundAgent
```ruby
agent = BackgroundAgent.new
scheduler = BackgroundJobScheduler.new(agent)
job_id = scheduler.schedule_job('analyze_text', { 'text' => 'Sample' })
scheduler.execute_pending_jobs
```

### WebAutomationAgent
```ruby
agent = WebAutomationAgent.new(client)
agent.scrape_and_analyze('https://example.com', 'Analyze this page')
```

## Requirements

- Ruby 2.7+
- Anthropic API key (get one at https://console.anthropic.com/)

