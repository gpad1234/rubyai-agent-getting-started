# 🚀 Web GUI Quick Start Guide

## Overview
The web GUI provides an interactive interface for Claude AI agents with real-time message logging and visualization.

## Prerequisites
- Ruby 3.4.7+
- `.env` file with `ANTHROPIC_API_KEY`
- Gems installed: `bundle install`

## Starting the Web GUI

```bash
bundle exec ruby web_gui_simple.rb
```

**Output:**
```
🚀 Ruby AI Agents Web GUI Starting...
📍 Server running at http://localhost:3000
💬 Open your browser and start chatting!
📁 Logs stored in: ./logs/
⚠️  Press Ctrl+C to stop the server
```

## Accessing the Interface

Open your browser and navigate to:
```
http://localhost:3000
```

## Features

### 💬 Chat Tab
- **Send Messages**: Type any message and select an agent type
- **Agent Types**:
  - **Concurrent Agent**: Fast, parallel task execution
  - **Background Agent**: Job scheduling and queueing
- **Message History**: All messages displayed in real-time
- **Statistics**: View total messages, responses, and errors

### 📋 Logs Tab
- **Message Log**: Complete history with timestamps
- **Type Indicators**: User messages, AI responses, errors
- **Filter**: View specific time ranges
- **Export**: Download logs for analysis

### ⚙️ Status Tab
- **API Health**: Check service status
- **Performance Metrics**: Response times and throughput
- **System Stats**: Memory and CPU usage

## API Endpoints

### Core Endpoints
```bash
# Send a message
POST /api/send_message
Content-Type: application/json
{
  "message": "Your question here",
  "agent_type": "concurrent"  # or "background"
}

# Get message history
GET /api/messages?limit=100

# Clear all messages
GET /api/clear_messages

# Get available logs
GET /api/logs

# Read specific log file
GET /api/log/messages_20251114.log

# Health check
GET /health
```

## Examples

### Example 1: Ask About Ruby
```
Agent: Concurrent Agent
Message: What is Ruby programming language?
Response: Ruby is a dynamic, interpreted programming language...
```

### Example 2: Content Generation
```
Agent: Background Agent
Message: Generate a haiku about programming
Response: Code flows like water / Logic bends to human will / Art meets engineering
```

### Example 3: Code Explanation
```
Agent: Concurrent Agent
Message: Explain what a closure is in Ruby
Response: A closure is a function or block that captures...
```

## Message Logging

Messages are automatically logged to `logs/messages_YYYYMMDD.log` in JSON format:

```json
{
  "timestamp": "2025-11-14T17:28:38.123Z",
  "type": "user_message",
  "sender": "User",
  "message": "What is Ruby?",
  "metadata": {
    "agent": "concurrent"
  }
}
```

## Troubleshooting

### Port Already In Use
```bash
# Kill the process on port 3000
lsof -ti:3000 | xargs kill -9
# Then restart
bundle exec ruby web_gui_simple.rb
```

### API Key Error
```
Error: Anthropic client not initialized. Check ANTHROPIC_API_KEY
```
**Solution**: Ensure `.env` file has valid `ANTHROPIC_API_KEY`

### No Responses
1. Check that server is running: `curl http://localhost:3000/health`
2. Verify API key is valid
3. Check network connectivity
4. Review logs: `tail -f logs/messages_*.log`

### Slow Responses
- Responses typically take 2-3 seconds with Haiku model
- Concurrent agent may take longer for parallel tasks
- Check browser console for network errors

## Performance Tips

1. **Use Haiku Model**: Faster, 70% speed improvement over Sonnet
2. **Concurrent Agent**: Best for parallel tasks
3. **Background Agent**: Good for scheduled work
4. **Clear Messages**: Keeps UI responsive - use "Clear" button regularly

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Web Browser                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  public/index.html (400 lines HTML/CSS/JS)            │ │
│  │  - Real-time message display                          │ │
│  │  - Chat input & agent selector                        │ │
│  │  - Statistics & logs viewer                           │ │
│  │  - Auto-refresh every 3 seconds                       │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────┬──────────────────────────────────────────────┘
               │ HTTP REST API
┌──────────────▼──────────────────────────────────────────────┐
│          web_gui_simple.rb (Sinatra Server)                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  6 API Endpoints                                       │ │
│  │  - POST /api/send_message (Agent execution)           │ │
│  │  - GET  /api/messages (Message history)               │ │
│  │  - GET  /api/clear_messages (Clear logs)              │ │
│  │  - GET  /api/logs (List log files)                    │ │
│  │  - GET  /api/log/:filename (Read log file)            │ │
│  │  - GET  /health (Service status)                      │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  MessageLogger Class                                   │ │
│  │  - JSON persistence to logs/                          │ │
│  │  - In-memory caching                                  │ │
│  │  - Daily log rotation                                 │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────┬──────────────────────────────────────────────┘
               │ Agent Selection
    ┌──────────┴──────────┐
    │                      │
┌───▼──────────────┐  ┌────▼──────────────┐
│ ConcurrentAgent  │  │ BackgroundAgent  │
│ (Promises,       │  │ (Job Queue,      │
│  Futures)        │  │  Scheduler)      │
└───┬──────────────┘  └────┬──────────────┘
    │                      │
    └──────────┬───────────┘
               │ Claude API
        ┌──────▼──────┐
        │ Anthropic   │
        │ API         │
        │ claude-3.5  │
        │ haiku       │
        └─────────────┘
```

## Next Steps

1. **Customize Agents**: Edit `lib/concurrent_agent.rb` or `lib/background_agent.rb`
2. **Add Agents**: Create new agent classes and update web_gui_simple.rb
3. **Enhance UI**: Modify `public/index.html` for custom styling
4. **Deploy**: Use Docker or deploy to cloud platform
5. **Monitor**: Review logs in `logs/` directory

## Configuration

### Change Port
Edit line 16 in `web_gui_simple.rb`:
```ruby
set :port, 4000  # Change from 3000 to 4000
```

### Change Log Directory
Edit line 66 in `web_gui_simple.rb`:
```ruby
LOG_DIR = 'mylogs'  # Change from 'logs' to 'mylogs'
```

### Modify Agents
Available agents in `web_gui_simple.rb` POST route (lines 101-106):
```ruby
when 'concurrent'
  # Uses ConcurrentAgent from lib/concurrent_agent.rb
when 'background'
  # Uses BackgroundAgent from lib/background_agent.rb
```

Add new agents by:
1. Creating agent class in `lib/`
2. Adding require statement at top of `web_gui_simple.rb`
3. Adding case statement in POST route

## Production Deployment

For production, consider:
1. Set `set :environment, :production` in web_gui_simple.rb
2. Use production web server (Puma with multiple workers)
3. Add authentication middleware
4. Implement rate limiting
5. Use persistent database instead of JSON logs
6. Deploy with Docker container

## Support

For issues:
1. Check logs: `tail -f logs/messages_*.log`
2. View browser console: F12 → Console tab
3. Test health endpoint: `curl http://localhost:3000/health`
4. Review agent implementations in `lib/` directory

## License

MIT License - See LICENSE file
