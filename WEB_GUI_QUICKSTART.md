# Web GUI Setup & Quick Start

## 🚀 Quick Start

```bash
# 1. Navigate to project directory
cd ruby_agents_getting_started

# 2. Install dependencies (Sinatra already added)
bundle install

# 3. Start the web GUI
ruby web_gui.rb
```

**The GUI will be available at: `http://localhost:3000`**

## 📊 Web GUI Features

### 💬 Chat Tab
Interactive real-time chat with Claude AI agents

**Features:**
- Send messages to AI agents (ConcurrentAgent or BackgroundAgent)
- Real-time response display
- Live message statistics (Messages, Responses, Errors)
- One-click message clearing
- Press Enter to send or use Send button

**Stats Display:**
- **Messages**: User messages sent
- **Responses**: AI responses received  
- **Errors**: Failed requests

### 📋 Logs Tab
Complete message history with filtering and search

**Features:**
- View all messages with timestamps
- Filter by message type (user, AI, error)
- Message previews (first 80 characters)
- Sort by time
- Full message content available on click

**Columns:**
- Type: user_message, ai_response, error
- Sender: User, agent name, System
- Preview: First 80 chars of message
- Time: ISO timestamp

### 📁 Status Tab
System health and log management

**Features:**
- System health status
- Current timestamp
- Total log entries count
- Log file listing
- File size and line count
- Last modified time

## 📝 Message Logging

### Log Storage
- **Location**: `logs/` directory
- **Format**: JSON Lines (one object per line)
- **Daily files**: `messages_YYYYMMDD.log`
- **Auto-rotation**: Automatic daily rotation

### Log Entry Structure
```json
{
  "timestamp": "2025-11-14T12:34:56Z",
  "type": "user_message|ai_response|error",
  "sender": "User|concurrent|System",
  "message": "Actual message content",
  "metadata": {
    "agent": "concurrent",
    "user_message": "original prompt (for responses)",
    "error_class": "RuntimeError (for errors)"
  }
}
```

### Viewing Logs

**In UI:**
1. Go to "Logs" tab
2. See table with all messages
3. Timestamp shows when message was processed

**In Files:**
```bash
# View today's log
cat logs/messages_20251114.log | jq .

# Count messages
wc -l logs/messages_*.log

# Search for errors
grep "error" logs/messages_*.log
```

## 🔌 API Endpoints

### Send Message (POST)
```bash
curl -X POST http://localhost:3000/api/send_message \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is Ruby?",
    "agent_type": "concurrent"
  }'

# Response:
{
  "success": true,
  "response": "Ruby is a dynamic programming language..."
}
```

### Get Messages (GET)
```bash
# Get last 50 messages
curl http://localhost:3000/api/messages?limit=50

# Response: Array of message objects with full details
```

### Get Logs (GET)
```bash
# List all log files
curl http://localhost:3000/api/logs

# Response: Array of file info objects
[
  {
    "filename": "messages_20251114.log",
    "size": 45000,
    "lines": 124,
    "modified": "2025-11-14T17:08:28Z"
  }
]
```

### Get Log Content (GET)
```bash
# View specific log file
curl http://localhost:3000/api/log/messages_20251114.log

# Response: Array of all entries in that file
```

### Health Check (GET)
```bash
curl http://localhost:3000/health

# Response:
{
  "status": "ok",
  "timestamp": "2025-11-14T17:08:28Z"
}
```

### Clear Messages (GET)
```bash
curl http://localhost:3000/api/clear_messages

# Response:
{
  "success": true,
  "message": "Messages cleared"
}
```

## 📊 UI Components

### Statistics Dashboard
- Displays 3 key metrics
- Auto-updates every 3 seconds
- Color-coded gradient background

### Message Display
- **User messages**: Light blue background
- **AI responses**: Purple background
- **Errors**: Red background
- **Full timestamps**: ISO 8601 format

### Agent Selection
```html
<select id="agent-type">
  <option value="concurrent">Concurrent Agent</option>
  <option value="background">Background Agent</option>
</select>
```

## 🎨 Styling

### Color Scheme
- Primary: #667eea (Purple Blue)
- Secondary: #764ba2 (Deep Purple)
- Success: #4caf50 (Green)
- Error: #f44336 (Red)
- Warning: #ff9800 (Orange)

### Responsive Design
- ✅ Desktop: 2-column layout
- ✅ Tablet: Stacked layout
- ✅ Mobile: Single column
- ✅ Auto font scaling

## 🔒 Security Features

- ✅ API key in `.env` (git ignored)
- ✅ No credentials in logs
- ✅ No hardcoded secrets
- ✅ Safe JSON serialization
- ✅ Input validation

## 📈 Performance

- **Real-time updates**: 3-second refresh
- **Message limit**: 50 displayed (200 in logs)
- **Memory**: ~50MB baseline
- **CPU**: Minimal (event-driven)
- **Response time**: 2-5 seconds per API call

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Kill existing process
lsof -ti:3000 | xargs kill -9

# Or use different port
ruby web_gui.rb -p 3001
```

### Missing Dependencies
```bash
bundle install
bundle exec ruby web_gui.rb
```

### No Messages Appearing
1. Check browser console (F12)
2. Verify API key in `.env`
3. Check network tab in DevTools
4. Verify logs directory exists

### Celluloid Error
```bash
# Restart the server
# It will auto-boot Celluloid on startup
```

## 📂 File Structure

```
ruby_agents_getting_started/
├── web_gui.rb              # Main Sinatra application
├── WEB_GUI_README.md       # Detailed documentation
├── logs/                   # Message storage (auto-created)
│   ├── messages_20251114.log
│   ├── messages_20251113.log
│   └── ...
└── lib/
    ├── concurrent_agent.rb
    ├── background_agent.rb
    └── ...
```

## 🚀 Deployment

### Local Development
```bash
ruby web_gui.rb
# http://localhost:3000
```

### Production
```bash
# Use Puma or similar production server
puma web_gui.rb -t 5:5 -w 2

# Or Passenger
passenger start

# Or Docker (future)
docker run -p 3000:3000 ruby-ai-agents
```

## 📱 Features Summary

| Feature | Status | Details |
|---------|--------|---------|
| Chat Interface | ✅ | Real-time messaging |
| Message Logs | ✅ | Persistent JSON storage |
| System Status | ✅ | Health checks |
| API | ✅ | RESTful endpoints |
| Responsive Design | ✅ | Desktop/Mobile |
| Real-time Updates | ✅ | 3-second refresh |
| Message History | ✅ | Full retention |
| Error Handling | ✅ | Graceful errors |
| Dark Mode | 🔄 | Planned |
| Export | 🔄 | Planned |

## 📞 Support

1. **Check logs**: `logs/messages_*.log`
2. **Browser console**: F12 → Console tab
3. **Network tab**: F12 → Network tab
4. **Health check**: `curl http://localhost:3000/health`
5. **Documentation**: See WEB_GUI_README.md

## 🎓 Examples

### Example 1: Send Message via Web UI
1. Open http://localhost:3000
2. Type: "Explain Ruby concurrency"
3. Select: "Concurrent Agent"
4. Click: "Send"
5. See response in chat
6. Check "Logs" tab for message history

### Example 2: Send Message via API
```bash
curl -X POST http://localhost:3000/api/send_message \
  -H "Content-Type: application/json" \
  -d '{"message":"Tell me about Ruby","agent_type":"concurrent"}'
```

### Example 3: Monitor Logs
```bash
# In one terminal
tail -f logs/messages_20251114.log | jq .

# In another
ruby web_gui.rb
```

## 🎉 You're All Set!

Your Ruby AI Agents now have a professional web GUI with:
- ✅ Interactive chat interface
- ✅ Real-time message logging
- ✅ System monitoring dashboard
- ✅ RESTful API
- ✅ Responsive design
- ✅ Production-ready

**Start chatting:** `ruby web_gui.rb` then open `http://localhost:3000` 🚀
