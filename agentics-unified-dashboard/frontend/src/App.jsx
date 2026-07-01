// ============================================================================
// AGENTICS UNIFIED DASHBOARD — FRONTEND
// ============================================================================
// React.js dashboard for all Agentics services
// Real-time health monitoring, tool discovery, chat interface
//
// ============================================================================

import React, { useState, useEffect, useRef } from 'react';
import './App.css';

// ============================================================================
// COMPONENTS
// ============================================================================

// Dashboard Header
function DashboardHeader() {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header className="dashboard-header">
      <div className="header-content">
        <h1>🤖 Agentics Unified Dashboard</h1>
        <div className="header-meta">
          <span className="time">{time.toLocaleTimeString()}</span>
          <span className="date">{time.toLocaleDateString()}</span>
        </div>
      </div>
    </header>
  );
}

// Service Health Card
function ServiceHealthCard({ name, service }) {
  const statusClass = service.status === 'ok' ? 'healthy' : 'unhealthy';
  const icon = service.status === 'ok' ? '✓' : '✗';

  return (
    <div className={`service-card ${statusClass}`}>
      <div className="service-header">
        <span className="service-icon">{icon}</span>
        <span className="service-name">{name}</span>
      </div>
      <div className="service-details">
        <span className="status-badge">{service.status}</span>
        <span className="status-code">{service.statusCode}</span>
      </div>
      {service.error && <div className="error-text">{service.error}</div>}
    </div>
  );
}

// Services Health Panel
function ServicesPanel({ health }) {
  if (!health || Object.keys(health).length === 0) {
    return <div className="panel loading">Loading services...</div>;
  }

  const healthy = Object.values(health).filter((s) => s.status === 'ok').length;
  const total = Object.keys(health).length;

  return (
    <div className="panel services-panel">
      <h2>📊 Service Health</h2>
      <div className="health-summary">
        <span className="summary-stat">
          <strong>{healthy}</strong>/{total} Services Healthy
        </span>
        <div className="health-bar">
          <div className="health-fill" style={{ width: `${(healthy / total) * 100}%` }} />
        </div>
      </div>
      <div className="services-grid">
        {Object.entries(health).map(([name, service]) => (
          <ServiceHealthCard key={name} name={name} service={service} />
        ))}
      </div>
    </div>
  );
}

// Models Panel
function ModelsPanel({ models }) {
  const [selectedModel, setSelectedModel] = useState(models[0]?.name || '');

  return (
    <div className="panel models-panel">
      <h2>🧠 Available Models</h2>
      <div className="models-list">
        {models.length === 0 ? (
          <div className="no-data">No models loaded</div>
        ) : (
          models.map((model) => (
            <div
              key={model.name}
              className={`model-item ${selectedModel === model.name ? 'selected' : ''}`}
              onClick={() => setSelectedModel(model.name)}
            >
              <div className="model-name">{model.name}</div>
              <div className="model-size">{(model.size / 1024 / 1024 / 1024).toFixed(2)} GB</div>
            </div>
          ))
        )}
      </div>
      {selectedModel && (
        <div className="model-details">
          <h3>Selected: {selectedModel}</h3>
          <button className="btn btn-primary">Use in Chat</button>
        </div>
      )}
    </div>
  );
}

// Chat Panel
function ChatPanel() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [model, setModel] = useState('llama3.2:3b');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async () => {
    if (!input.trim()) return;

    setMessages((prev) => [...prev, { role: 'user', content: input }]);
    setInput('');
    setLoading(true);

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: input, model }),
      });

      const data = await response.json();
      setMessages((prev) => [...prev, { role: 'assistant', content: data.response || data.message }]);
    } catch (error) {
      setMessages((prev) => [...prev, { role: 'error', content: `Error: ${error.message}` }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="panel chat-panel">
      <h2>💬 Chat Interface</h2>
      <div className="chat-container">
        <div className="messages">
          {messages.map((msg, idx) => (
            <div key={idx} className={`message message-${msg.role}`}>
              <div className="message-role">{msg.role === 'user' ? '👤' : '🤖'}</div>
              <div className="message-content">{msg.content}</div>
            </div>
          ))}
          {loading && <div className="message message-loading">Thinking...</div>}
          <div ref={messagesEndRef} />
        </div>
        <div className="chat-input-section">
          <div className="model-selector">
            <label>Model:</label>
            <select value={model} onChange={(e) => setModel(e.target.value)}>
              <option>llama3.2:3b</option>
              <option>qwen2.5-coder:7b</option>
              <option>nomic-embed-text</option>
            </select>
          </div>
          <div className="input-group">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
              placeholder="Type a message..."
              disabled={loading}
            />
            <button onClick={sendMessage} disabled={loading} className="btn btn-primary">
              Send
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Tools Panel
function ToolsPanel() {
  const [tools, setTools] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTools();
  }, []);

  const fetchTools = async () => {
    try {
      const response = await fetch('/api/tools/available');
      const data = await response.json();
      setTools(data.tools || []);
    } catch (error) {
      console.error('Error fetching tools:', error);
    } finally {
      setLoading(false);
    }
  };

  const executeTool = async (tool) => {
    try {
      const response = await fetch('/api/tools/execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool: tool.name, params: {} }),
      });
      const data = await response.json();
      alert(`Tool executed: ${JSON.stringify(data)}`);
    } catch (error) {
      alert(`Error executing tool: ${error.message}`);
    }
  };

  return (
    <div className="panel tools-panel">
      <h2>🛠️ Available Tools</h2>
      {loading ? (
        <div className="loading">Loading tools...</div>
      ) : (
        <div className="tools-grid">
          {tools.length === 0 ? (
            <div className="no-data">No tools available</div>
          ) : (
            tools.map((tool) => (
              <div key={tool.name} className="tool-card">
                <h3>{tool.name}</h3>
                <p>{tool.description}</p>
                <button
                  className="btn btn-secondary"
                  onClick={() => executeTool(tool)}
                >
                  Execute
                </button>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}

// Workflows Panel
function WorkflowsPanel() {
  const [workflows, setWorkflows] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchWorkflows();
  }, []);

  const fetchWorkflows = async () => {
    try {
      const response = await fetch('/api/workflows');
      const data = await response.json();
      setWorkflows(data.workflows || data || []);
    } catch (error) {
      console.error('Error fetching workflows:', error);
    } finally {
      setLoading(false);
    }
  };

  const executeWorkflow = async (workflowId) => {
    try {
      const response = await fetch('/api/workflows/execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ workflowId, data: {} }),
      });
      const data = await response.json();
      alert(`Workflow executed: ${JSON.stringify(data)}`);
    } catch (error) {
      alert(`Error executing workflow: ${error.message}`);
    }
  };

  return (
    <div className="panel workflows-panel">
      <h2>⚙️ Workflows (n8n)</h2>
      {loading ? (
        <div className="loading">Loading workflows...</div>
      ) : (
        <div className="workflows-list">
          {workflows.length === 0 ? (
            <div className="no-data">No workflows configured</div>
          ) : (
            workflows.map((wf) => (
              <div key={wf.id || wf.name} className="workflow-item">
                <div className="workflow-name">{wf.name}</div>
                <button
                  className="btn btn-secondary btn-small"
                  onClick={() => executeWorkflow(wf.id)}
                >
                  Execute
                </button>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// MAIN APP
// ============================================================================

export default function App() {
  const [health, setHealth] = useState({});
  const [models, setModels] = useState([]);
  const [summary, setSummary] = useState(null);
  const ws = useRef(null);

  useEffect(() => {
    // Fetch initial data
    fetchSummary();
    fetchModels();

    // Setup WebSocket for real-time updates
    setupWebSocket();

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, []);

  const fetchSummary = async () => {
    try {
      const response = await fetch('/api/dashboard/summary');
      const data = await response.json();
      setSummary(data);
      setHealth(data.services.details);
    } catch (error) {
      console.error('Error fetching summary:', error);
    }
  };

  const fetchModels = async () => {
    try {
      const response = await fetch('/api/ollama/models');
      const data = await response.json();
      setModels(data.models || []);
    } catch (error) {
      console.error('Error fetching models:', error);
    }
  };

  const setupWebSocket = () => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws.current = new WebSocket(`${protocol}//${window.location.host}`);

    ws.current.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'health') {
        setHealth(data.data);
      }
    };

    ws.current.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  };

  return (
    <div className="app">
      <DashboardHeader />
      <main className="dashboard-main">
        <div className="dashboard-grid">
          <ServicesPanel health={health} />
          <ModelsPanel models={models} />
          <ChatPanel />
          <ToolsPanel />
          <WorkflowsPanel />
        </div>
      </main>
    </div>
  );
}
