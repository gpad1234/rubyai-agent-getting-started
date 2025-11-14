# Ruby AI Agents - Technical Specifications

## 1. ConcurrentAgent - Concurrent-ruby

### Overview
A parallel processing agent using `concurrent-ruby` gem for managing multiple AI tasks with futures, promises, and atomic operations.

### Key Components
- **FixedThreadPool**: 5 worker threads for parallel execution
- **Futures**: Non-blocking asynchronous task execution
- **Promises**: Chain-able async operations with `.then` and `.rescue`
- **AtomicFixnum**: Thread-safe counter for task tracking

### Architecture
```
┌─────────────────────────────────────┐
│   ConcurrentAgent                   │
├─────────────────────────────────────┤
│ - @client: Anthropic::Client        │
│ - @executor: FixedThreadPool(5)     │
└─────────────────────────────────────┘
        ↓
    ┌───┬───┬───┬───┬───┐
    │ T1│ T2│ T3│ T4│ T5│ (Worker Threads)
    └───┴───┴───┴───┴───┘
        ↓     ↓     ↓
    Future results collected
```

### Public Methods
| Method | Description | Returns |
|--------|-------------|---------|
| `execute_parallel_tasks(tasks)` | Run multiple tasks concurrently | Array of results |
| `execute_with_promises(prompt)` | Chain async operations | Promise value |
| `execute_with_tracking(prompts)` | Track progress with atomic counter | Array of results |

### Performance Characteristics
- **Concurrency Level**: 5 threads
- **Model**: Claude 3.5 Haiku
- **Max Tokens**: 500
- **Ideal for**: Parallel API calls, batch processing
- **Latency**: Reduced ~70% vs sequential (5 calls take ~2-3s vs 10-15s)

### Code Example
```ruby
agent = ConcurrentAgent.new(client)
tasks = [
  { name: "Task 1", prompt: "Question 1" },
  { name: "Task 2", prompt: "Question 2" }
]
results = agent.execute_parallel_tasks(tasks)
```

### Threading Model
- **Type**: Thread-based concurrency
- **Thread Safety**: Yes (via Concurrent gem)
- **Deadlock Risk**: Low (no explicit locking)
- **Memory**: ~1MB per thread + stack overhead

---

## 2. CelluloidAgent - Actor Model Concurrency

### Overview
Message-passing concurrency using the Actor model with `celluloid` gem. Actors are concurrent objects that receive and process messages asynchronously.

### Key Components
- **CelluloidAgent**: Individual actor for processing messages
- **AgentSupervisor**: Manages pool of actors with work distribution
- **Message Queue**: Async message delivery per actor
- **Conversation History**: Per-actor state management

### Architecture
```
┌──────────────────────────────────┐
│   AgentSupervisor                │
├──────────────────────────────────┤
│ Pool Size: 3                     │
│ Agent Pool: [A0, A1, A2]         │
└──────────────────────────────────┘
        ↓        ↓        ↓
    ┌────────────────────────────┐
    │ CelluloidAgent (Actor)     │ (x3)
    ├────────────────────────────┤
    │ - @client                  │
    │ - @conversation_history    │
    │ - Message Mailbox          │
    └────────────────────────────┘
```

### Public Methods
| Method | Description | Returns |
|--------|-------------|---------|
| `process_message(message, context)` | Async message processing | Future/Result |
| `get_history()` | Retrieve conversation history | Array of dicts |
| `clear_history()` | Clear stored messages | Nil |
| `process_batch(messages)` | Sequential message processing | Array of results |

### Supervisor Methods
| Method | Description | Returns |
|--------|-------------|---------|
| `distribute_work(tasks)` | Load balance across pool | Array of results |
| `status()` | Get pool health metrics | Hash with stats |

### Performance Characteristics
- **Concurrency Level**: Actor pool (default 3)
- **Model**: Claude 3.5 Haiku
- **Max Tokens**: 500
- **Message Queue**: Unbounded
- **Ideal for**: Stateful processing, long-running tasks, distributed work
- **Latency**: Parallel processing with actor pool

### Code Example
```ruby
supervisor = AgentSupervisor.new(client, 3)
tasks = ["Task 1", "Task 2", "Task 3"]
results = supervisor.distribute_work(tasks)
status = supervisor.status
```

### Actor Model Properties
- **Type**: Message-based actors
- **Communication**: Async message passing
- **Isolation**: Complete state isolation per actor
- **Fault Tolerance**: Supervisor restarts failed actors
- **Memory**: ~2MB per actor + mailbox buffer

---

## 3. BackgroundAgent - Job Processing & Scheduling

### Overview
Resque/Sidekiq-style background job processing with job scheduling, status tracking, and task queue management.

### Key Components
- **BackgroundAgent**: Core worker performing AI tasks
- **BackgroundJobScheduler**: Job queue with scheduling
- **Job State Machine**: pending → running → completed/failed
- **Task Types**: Extensible job type system

### Architecture
```
┌─────────────────────────────────┐
│   BackgroundJobScheduler        │
├─────────────────────────────────┤
│ @jobs: [                        │
│   {id, type, payload, status}   │
│ ]                               │
└─────────────────────────────────┘
        ↓
┌─────────────────────────────────┐
│   BackgroundAgent               │
├─────────────────────────────────┤
│ - perform(type, payload)        │
│ - analyze_text(text)            │
│ - generate_content(prompt)      │
│ - summarize(text)               │
│ - batch_process(items)          │
└─────────────────────────────────┘
```

### Job Types
| Type | Input | Output | Use Case |
|------|-------|--------|----------|
| `analyze_text` | `{text}` | Analysis result | Content analysis |
| `generate_content` | `{prompt, context}` | Generated content | Content creation |
| `summarize` | `{text}` | Summary | Text reduction |
| `batch_process` | `{items:[]}` | Array of results | Bulk operations |

### Public Methods
| Method | Description | Returns |
|--------|-------------|---------|
| `perform(task_type, payload)` | Execute job synchronously | Job result |
| `analyze_text(text)` | Analyze content with AI | Analysis dict |
| `generate_content(prompt, context)` | Generate with context | Content string |
| `summarize(text)` | Summarize text | Summary string |
| `batch_process(items)` | Process multiple items | Array of results |

### Scheduler Methods
| Method | Description | Returns |
|--------|-------------|---------|
| `schedule_job(type, payload, delay)` | Queue job for later | Job ID |
| `execute_pending_jobs()` | Run due jobs | Nil |
| `job_status(job_id)` | Get job state | Job dict |
| `list_jobs()` | All jobs in queue | Array |

### Performance Characteristics
- **Model**: Claude 3.5 Haiku
- **Max Tokens**: 500-1000
- **Scheduling**: Delay-based (no persistent storage)
- **Concurrency**: Sequential (single-threaded)
- **Ideal for**: Deferred tasks, bulk processing, stateful workflows
- **Reliability**: In-memory (no persistence)

### Job States
```
pending → running → completed ✅
                 ↘ failed ❌
```

### Code Example
```ruby
agent = BackgroundAgent.new(client)
scheduler = BackgroundJobScheduler.new(agent)

job_id = scheduler.schedule_job('analyze_text', {'text' => 'Sample'}, delay=5)
scheduler.execute_pending_jobs
status = scheduler.job_status(job_id)
```

### Storage & Persistence
- **Queue Storage**: In-memory Array
- **Persistence**: None (restarts lose jobs)
- **Max Queue Size**: Unbounded
- **Memory**: ~1KB per job

---

## 4. WebAutomationAgent - Web Scraping & Automation

### Overview
Web automation and scraping agent using `mechanize` gem for HTTP interactions with AI-powered analysis.

### Key Components
- **Mechanize Browser**: HTTP client with session management
- **Page Parser**: Nokogiri-based DOM parsing
- **Content Analyzer**: Claude-powered page understanding
- **Link Extractor**: Automated navigation discovery

### Architecture
```
┌──────────────────────────────┐
│   WebAutomationAgent         │
├──────────────────────────────┤
│ - @client: Anthropic         │
│ - @mechanize: Mechanize      │
└──────────────────────────────┘
        ↓
    ┌─────────────────────┐
    │  HTTP Request       │
    └─────────────────────┘
        ↓
    ┌─────────────────────┐
    │  HTML Response      │
    └─────────────────────┘
        ↓
    ┌─────────────────────┐
    │  DOM Parsing        │
    │  (Nokogiri/CSS)     │
    └─────────────────────┘
        ↓
    ┌─────────────────────┐
    │  Claude Analysis    │
    └─────────────────────┘
```

### Public Methods
| Method | Description | Returns |
|--------|-------------|---------|
| `scrape_and_analyze(url, prompt)` | Fetch and analyze page | Analysis dict |
| `extract_and_analyze_links(url, max)` | Get links with insight | Analysis dict |
| `search_and_extract(url, selector, prompt)` | Query elements | Analysis dict |
| `fill_and_submit_form(url, selector, fields)` | Form automation (disabled) | Form dict |
| `monitor_page_changes(url, interval, duration)` | Track changes over time | Array of changes |
| `download_and_analyze(url, doc_type)` | Fetch document | Analysis dict |

### Performance Characteristics
- **Model**: Claude 3.5 Haiku
- **Max Tokens**: 500-800
- **HTTP Timeout**: Default (20s)
- **Parser**: Nokogiri (C-based, fast)
- **Content Limit**: 3000 chars (truncated for API)
- **Ideal for**: Web data gathering, content analysis, monitoring

### User Agent
```
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)
AppleWebKit/537.36
```

### Network Requirements
- **HTTP/HTTPS**: Yes
- **Cookies**: Automatic management
- **Redirects**: Automatic follow
- **Meta Refresh**: Auto-follow enabled
- **JS Rendering**: Not supported (use Selenium for JS-heavy sites)

### Code Example
```ruby
agent = WebAutomationAgent.new(client)

# Scrape and analyze
result = agent.scrape_and_analyze('https://example.com', 'Analyze this page')

# Extract links
links = agent.extract_and_analyze_links('https://example.com', 5)

# Monitor for changes
changes = agent.monitor_page_changes('https://example.com', interval=60, duration=300)
```

### Limitations
- **JavaScript**: Not executed (static HTML only)
- **Authentication**: Basic auth supported, OAuth not
- **File Upload**: Not supported
- **Rate Limiting**: No built-in backoff
- **Storage**: No local caching

---

## Comparison Matrix

| Feature | Concurrent | Celluloid | Background | Web |
|---------|-----------|-----------|-----------|-----|
| **Concurrency** | Threads | Actors | Sequential | Threads |
| **Throughput** | High | High | Low | Medium |
| **Latency** | Low | Low | Variable | Medium-High |
| **State Management** | Minimal | Per-actor | Per-job | Per-session |
| **Error Handling** | Exception | Actor restart | Try-catch | HTTP errors |
| **Ideal Use** | Parallel API | Message queue | Deferred jobs | Web data |
| **Learning Curve** | Easy | Hard | Medium | Medium |
| **Production Ready** | Yes | Yes | Yes | Yes |

---

## API Quota & Cost Considerations

All agents use **Claude 3.5 Haiku** for cost efficiency:

### Token Costs (Estimated)
- **Input**: $0.80 / 1M tokens
- **Output**: $4.00 / 1M tokens
- **Concurrent (5 calls)**: ~5000 tokens total
- **Celluloid (5 calls)**: ~5000 tokens total
- **Background (5 jobs)**: ~5000 tokens total
- **Web (1 page + analysis)**: ~2000 tokens

### Request Rate Limits
- **RPM**: 600 (Regional)
- **TPM**: 40,000
- **Concurrent Requests**: 200

---

## Selection Guide

### Use ConcurrentAgent when:
- ✅ Processing multiple independent tasks
- ✅ Need maximum throughput
- ✅ Simple parallel workflows
- ✅ No state sharing needed

### Use CelluloidAgent when:
- ✅ Building scalable systems
- ✅ Long-running concurrent operations
- ✅ Complex message passing
- ✅ Fault tolerance needed

### Use BackgroundAgent when:
- ✅ Deferring expensive operations
- ✅ Scheduling future tasks
- ✅ Maintaining job status
- ✅ Batch processing needed

### Use WebAutomationAgent when:
- ✅ Scraping web content
- ✅ AI-powered analysis of pages
- ✅ Monitoring website changes
- ✅ Extracting structured data
