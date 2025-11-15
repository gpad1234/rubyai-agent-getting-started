#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'sinatra'
require 'json'
require 'fileutils'
require 'time'

require_relative 'lib/concurrent_agent'
require_relative 'lib/background_agent'

# Configure Sinatra
set :port, 3000
set :bind, '0.0.0.0'
set :sessions, true

# Ensure logs directory exists
LOG_DIR = 'logs'
FileUtils.mkdir_p(LOG_DIR) unless Dir.exist?(LOG_DIR)

# Message logger class
class MessageLogger
  def initialize(log_dir = 'logs')
    @log_dir = log_dir
    @messages = []
    load_messages
  end

  def log_message(type, sender, message, metadata = {})
    entry = {
      timestamp: Time.now.iso8601,
      type: type,
      sender: sender,
      message: message,
      metadata: metadata
    }
    @messages << entry
    write_to_file(entry)
    entry
  end

  def get_messages(limit = 100)
    @messages.last(limit)
  end

  def clear_messages
    @messages = []
    write_all_messages
  end

  private

  def write_to_file(entry)
    log_file = File.join(@log_dir, "messages_#{Time.now.strftime('%Y%m%d')}.log")
    File.open(log_file, 'a') do |f|
      f.puts entry.to_json
    end
  end

  def write_all_messages
    log_file = File.join(@log_dir, "messages_#{Time.now.strftime('%Y%m%d')}.log")
    File.write(log_file, @messages.map(&:to_json).join("\n"))
  end

  def load_messages
    log_file = File.join(@log_dir, "messages_#{Time.now.strftime('%Y%m%d')}.log")
    return unless File.exist?(log_file)

    File.readlines(log_file).each do |line|
      @messages << JSON.parse(line, symbolize_names: true)
    end
  end
end

# Initialize logger
@logger = MessageLogger.new(LOG_DIR)
@client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

# Boot Celluloid for actor system
begin
  Celluloid.boot
rescue => e
  # Already booted
end

# Routes

get '/' do
  erb :index
end

post '/api/send_message' do
  content_type :json
  
  data = JSON.parse(request.body.read)
  user_message = data['message']
  agent_type = data['agent_type'] || 'concurrent'

  begin
    # Log user message
    @logger.log_message('user_message', 'User', user_message, { agent: agent_type })

    # Process with agent
    response = case agent_type
               when 'concurrent'
                 agent = ConcurrentAgent.new(@client)
                 result = agent.execute_with_promises(user_message).value
                 result
               when 'background'
                 agent = BackgroundAgent.new(@client)
                 agent.perform('generate_content', { 'prompt' => user_message, 'context' => '' })
               else
                 'Unknown agent type'
               end

    # Log AI response
    @logger.log_message('ai_response', agent_type.titleize, response, { user_message: user_message })

    { success: true, response: response }.to_json
  rescue => e
    @logger.log_message('error', 'System', e.message, { user_message: user_message, error_class: e.class })
    { success: false, error: e.message }.to_json
  end
end

get '/api/messages' do
  content_type :json
  limit = params['limit']&.to_i || 100
  @logger.get_messages(limit).to_json
end

get '/api/clear_messages' do
  content_type :json
  @logger.clear_messages
  { success: true, message: 'Messages cleared' }.to_json
end

get '/logs' do
  erb :logs
end

get '/api/logs' do
  content_type :json
  
  log_files = Dir.glob(File.join(LOG_DIR, '*.log')).sort.reverse
  
  logs = log_files.map do |file|
    {
      filename: File.basename(file),
      size: File.size(file),
      lines: File.readlines(file).count,
      modified: File.mtime(file).iso8601
    }
  end

  logs.to_json
end

get '/api/log/:filename' do
  content_type :json
  
  filename = params['filename']
  filepath = File.join(LOG_DIR, filename)

  unless File.exist?(filepath) && filepath.start_with?(File.expand_path(LOG_DIR))
    return { error: 'File not found' }.to_json
  end

  entries = []
  File.readlines(filepath).each do |line|
    entries << JSON.parse(line, symbolize_names: true)
  end

  entries.to_json
end

get '/health' do
  content_type :json
  { status: 'ok', timestamp: Time.now.iso8601 }.to_json
end

__END__

@@ layout
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ruby AI Agents - Web GUI</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #333;
      min-height: 100vh;
      padding: 20px;
    }

    .container {
      max-width: 1200px;
      margin: 0 auto;
    }

    header {
      background: white;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }

    header h1 {
      color: #667eea;
      margin-bottom: 5px;
    }

    header p {
      color: #666;
      font-size: 14px;
    }

    .nav-tabs {
      display: flex;
      gap: 10px;
      margin-top: 15px;
      border-bottom: 2px solid #eee;
    }

    .nav-tabs a {
      padding: 10px 20px;
      text-decoration: none;
      color: #666;
      border-bottom: 3px solid transparent;
      cursor: pointer;
      transition: all 0.3s;
    }

    .nav-tabs a.active {
      color: #667eea;
      border-bottom-color: #667eea;
    }

    .content {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
    }

    .card {
      background: white;
      border-radius: 12px;
      padding: 20px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }

    .card h2 {
      color: #667eea;
      margin-bottom: 15px;
      font-size: 18px;
    }

    #messages {
      height: 400px;
      overflow-y: auto;
      border: 1px solid #eee;
      border-radius: 8px;
      padding: 10px;
      background: #f9f9f9;
    }

    .message {
      padding: 10px;
      margin-bottom: 10px;
      border-radius: 8px;
      border-left: 4px solid #667eea;
    }

    .message.user {
      background: #e3f2fd;
      border-left-color: #2196F3;
    }

    .message.ai {
      background: #f3e5f5;
      border-left-color: #667eea;
    }

    .message.error {
      background: #ffebee;
      border-left-color: #f44336;
    }

    .message-time {
      font-size: 12px;
      color: #999;
      margin-bottom: 5px;
    }

    .message-sender {
      font-weight: bold;
      color: #667eea;
      margin-bottom: 5px;
    }

    .message-text {
      word-wrap: break-word;
    }

    .input-group {
      display: flex;
      gap: 10px;
      margin-top: 15px;
    }

    input[type="text"], select {
      flex: 1;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 8px;
      font-size: 14px;
    }

    select {
      flex: 0 0 150px;
    }

    button {
      padding: 10px 20px;
      background: #667eea;
      color: white;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      font-weight: bold;
      transition: background 0.3s;
    }

    button:hover {
      background: #764ba2;
    }

    button:disabled {
      background: #ccc;
      cursor: not-allowed;
    }

    .table {
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }

    .table th {
      background: #f5f5f5;
      padding: 10px;
      text-align: left;
      font-weight: bold;
      border-bottom: 2px solid #ddd;
    }

    .table td {
      padding: 10px;
      border-bottom: 1px solid #eee;
    }

    .table tr:hover {
      background: #f9f9f9;
    }

    .log-content {
      font-family: 'Monaco', 'Courier New', monospace;
      font-size: 12px;
      background: #1e1e1e;
      color: #d4d4d4;
      padding: 15px;
      border-radius: 8px;
      overflow-x: auto;
      max-height: 500px;
      overflow-y: auto;
    }

    .log-entry {
      margin-bottom: 10px;
      padding: 5px;
      border-left: 2px solid #667eea;
      padding-left: 10px;
    }

    .badge {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: bold;
    }

    .badge-user {
      background: #e3f2fd;
      color: #1976d2;
    }

    .badge-ai {
      background: #f3e5f5;
      color: #6a1b9a;
    }

    .badge-error {
      background: #ffebee;
      color: #c62828;
    }

    .stats {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;
      margin-bottom: 15px;
    }

    .stat-box {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 15px;
      border-radius: 8px;
      text-align: center;
    }

    .stat-box .number {
      font-size: 24px;
      font-weight: bold;
    }

    .stat-box .label {
      font-size: 12px;
      opacity: 0.9;
    }

    .loading {
      display: inline-block;
      width: 12px;
      height: 12px;
      border: 2px solid #f3f3f3;
      border-top: 2px solid #667eea;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    .tab-content {
      display: none;
    }

    .tab-content.active {
      display: block;
    }

    @media (max-width: 768px) {
      .content {
        grid-template-columns: 1fr;
      }

      .stats {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>🚀 Ruby AI Agents - Web GUI</h1>
      <p>Interactive interface for Claude AI agents with real-time message logging</p>
      <div class="nav-tabs">
        <a href="#" class="nav-link active" data-tab="chat">💬 Chat</a>
        <a href="#" class="nav-link" data-tab="logs">📋 Logs</a>
        <a href="#" class="nav-link" data-tab="status">ℹ️ Status</a>
      </div>
    </header>

    <div class="content">
      <!-- Chat Tab -->
      <div id="chat" class="tab-content active">
        <div class="card">
          <h2>Chat Interface</h2>
          
          <div class="stats">
            <div class="stat-box">
              <div class="number" id="message-count">0</div>
              <div class="label">Messages</div>
            </div>
            <div class="stat-box">
              <div class="number" id="response-count">0</div>
              <div class="label">Responses</div>
            </div>
            <div class="stat-box">
              <div class="number" id="error-count">0</div>
              <div class="label">Errors</div>
            </div>
          </div>

          <div id="messages"></div>

          <div class="input-group">
            <select id="agent-type">
              <option value="concurrent">Concurrent Agent</option>
              <option value="background">Background Agent</option>
            </select>
            <input type="text" id="message-input" placeholder="Enter your message..." />
            <button id="send-btn" onclick="sendMessage()">Send</button>
            <button onclick="clearMessages()" style="background: #f44336;">Clear</button>
          </div>
        </div>
      </div>

      <!-- Logs Tab -->
      <div id="logs" class="tab-content">
        <div class="card">
          <h2>Message Logs</h2>
          <table class="table" id="logs-table">
            <thead>
              <tr>
                <th>Type</th>
                <th>Sender</th>
                <th>Message Preview</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody id="logs-body">
              <tr><td colspan="4" style="text-align: center; color: #999;">Loading...</td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Status Tab -->
      <div id="status" class="tab-content">
        <div class="card">
          <h2>System Status</h2>
          <div id="status-info" style="line-height: 2;">
            <p>🔄 Checking system status...</p>
          </div>
        </div>

        <div class="card">
          <h2>Log Files</h2>
          <table class="table" id="logfiles-table">
            <thead>
              <tr>
                <th>File</th>
                <th>Size</th>
                <th>Lines</th>
                <th>Modified</th>
              </tr>
            </thead>
            <tbody id="logfiles-body">
              <tr><td colspan="4" style="text-align: center; color: #999;">Loading...</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <script>
    const API_BASE = '/api';
    
    // Tab switching
    document.querySelectorAll('.nav-link').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const tab = link.getAttribute('data-tab');
        
        // Hide all tabs
        document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
        
        // Show selected tab
        document.getElementById(tab).classList.add('active');
        link.classList.add('active');
        
        if (tab === 'logs') loadLogs();
        if (tab === 'status') loadStatus();
      });
    });

    function sendMessage() {
      const input = document.getElementById('message-input');
      const agentType = document.getElementById('agent-type').value;
      const message = input.value.trim();

      if (!message) return;

      const btn = document.getElementById('send-btn');
      btn.disabled = true;
      btn.innerHTML = '<span class="loading"></span>';

      fetch(`${API_BASE}/send_message`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message, agent_type: agentType })
      })
      .then(r => r.json())
      .then(data => {
        input.value = '';
        btn.disabled = false;
        btn.innerHTML = 'Send';
        
        if (data.success) {
          loadMessages();
        } else {
          alert('Error: ' + data.error);
        }
      })
      .catch(e => {
        console.error(e);
        btn.disabled = false;
        btn.innerHTML = 'Send';
        alert('Network error: ' + e.message);
      });
    }

    function loadMessages() {
      fetch(`${API_BASE}/messages?limit=50`)
        .then(r => r.json())
        .then(messages => {
          const container = document.getElementById('messages');
          container.innerHTML = '';
          
          let userCount = 0, aiCount = 0, errorCount = 0;

          messages.forEach(msg => {
            const div = document.createElement('div');
            const msgClass = msg.type === 'user_message' ? 'user' : msg.type === 'error' ? 'error' : 'ai';
            div.className = `message ${msgClass}`;
            
            const time = new Date(msg.timestamp).toLocaleTimeString();
            const preview = msg.message.substring(0, 150) + (msg.message.length > 150 ? '...' : '');
            
            div.innerHTML = `
              <div class="message-time">${time}</div>
              <div class="message-sender">${msg.sender}</div>
              <div class="message-text">${preview}</div>
            `;
            container.appendChild(div);
            
            if (msg.type === 'user_message') userCount++;
            else if (msg.type === 'ai_response') aiCount++;
            else if (msg.type === 'error') errorCount++;
          });
          
          document.getElementById('message-count').textContent = userCount;
          document.getElementById('response-count').textContent = aiCount;
          document.getElementById('error-count').textContent = errorCount;
          
          container.scrollTop = container.scrollHeight;
        });
    }

    function loadLogs() {
      fetch(`${API_BASE}/messages?limit=200`)
        .then(r => r.json())
        .then(messages => {
          const tbody = document.getElementById('logs-body');
          tbody.innerHTML = '';

          if (messages.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; color: #999;">No logs yet</td></tr>';
            return;
          }

          messages.forEach(msg => {
            const tr = document.createElement('tr');
            const time = new Date(msg.timestamp).toLocaleTimeString();
            const preview = msg.message.substring(0, 80) + (msg.message.length > 80 ? '...' : '');
            
            tr.innerHTML = `
              <td><span class="badge badge-${msg.type === 'user_message' ? 'user' : msg.type === 'error' ? 'error' : 'ai'}">${msg.type}</span></td>
              <td>${msg.sender}</td>
              <td>${preview}</td>
              <td>${time}</td>
            `;
            tbody.appendChild(tr);
          });
        });
    }

    function loadStatus() {
      Promise.all([
        fetch(`${API_BASE}/health`).then(r => r.json()),
        fetch(`${API_BASE}/logs`).then(r => r.json())
      ])
      .then(([health, logs]) => {
        const statusDiv = document.getElementById('status-info');
        statusDiv.innerHTML = `
          <p>✅ <strong>Status:</strong> ${health.status.toUpperCase()}</p>
          <p>⏰ <strong>Time:</strong> ${new Date(health.timestamp).toLocaleString()}</p>
          <p>📁 <strong>Log Files:</strong> ${logs.length}</p>
          <p>💾 <strong>Total Logs:</strong> ${logs.reduce((sum, l) => sum + l.lines, 0)} entries</p>
        `;

        const tbody = document.getElementById('logfiles-body');
        tbody.innerHTML = '';

        logs.forEach(log => {
          const tr = document.createElement('tr');
          const size = (log.size / 1024).toFixed(2) + ' KB';
          const modified = new Date(log.modified).toLocaleString();
          
          tr.innerHTML = `
            <td>${log.filename}</td>
            <td>${size}</td>
            <td>${log.lines}</td>
            <td>${modified}</td>
          `;
          tbody.appendChild(tr);
        });
      });
    }

    function clearMessages() {
      if (confirm('Clear all messages?')) {
        fetch(`${API_BASE}/clear_messages`, { method: 'GET' })
          .then(r => r.json())
          .then(() => loadMessages());
      }
    }

    // Allow Enter key to send
    document.getElementById('message-input')?.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMessage();
    });

    // Load messages on page load
    loadMessages();
    setInterval(loadMessages, 3000);
  </script>
</body>
</html>
