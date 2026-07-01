# Agentics Unified Dashboard

## Overview

A **real-time, unified control panel** for the entire Agentics stack. Integrates all services (Ollama, Open WebUI, Orchestrator, n8n, tools, browser automation, monitoring) into a single dashboard with:

- ✅ **Real-time health monitoring** (14+ services)
- ✅ **Model management** (pull, list, switch models)
- ✅ **Chat interface** (direct LLM interaction)
- ✅ **Tool discovery & execution** (all business tools)
- ✅ **Workflow automation** (n8n workflows)
- ✅ **Browser automation** control
- ✅ **RAG/Vector DB** integration
- ✅ **Metrics & Monitoring** (Prometheus, Grafana, Loki)
- ✅ **GraphQL API** access

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  UNIFIED DASHBOARD FRONTEND (React)                 │
│  Port: 9999                                         │
│  - Service Health                                   │
│  - Models Panel                                     │
│  - Chat Interface                                   │
│  - Tools Browser                                    │
│  - Workflows Panel                                  │
└──────────────────┬──────────────────────────────────┘
                   │ WebSocket + REST
                   ▼
┌─────────────────────────────────────────────────────┐
│  UNIFIED DASHBOARD BACKEND (Node.js)                │
│  Port: 9000                                         │
│  - Health Checks                                    │
│  - Service Gateway                                  │
│  - Real-time Updates                                │
│  - Tool Integration                                 │
│  - Orchestration API                                │
└──────────────────┬──────────────────────────────────┘
                   │
       ┌───────────┼───────────┐
       ▼           ▼           ▼
   [Ollama]    [WebUI]    [Orchestrator]
       ▼           ▼           ▼
   [Tools API]  [n8n]     [Browser]
       ▼           ▼           ▼
  [Chroma]     [Tika]     [WAHA]
       ▼           ▼           ▼
  [MinIO]    [Prometheus] [Grafana]
```

---

## Quick Start

### 1. Build Images

```powershell
cd C:\DeerpShit\Agentics

# Build backend
docker build -f agentics-unified-dashboard/backend/Dockerfile `
  -t unified-dashboard-backend:latest `
  agentics-unified-dashboard/backend

# Build frontend
docker build -f agentics-unified-dashboard/frontend/Dockerfile `
  -t unified-dashboard-frontend:latest `
  agentics-unified-dashboard/frontend
```

### 2. Start Stack with Dashboard

```powershell
docker compose \
  -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  -f docker-compose.unified-dashboard.override.yml \
  up -d
```

### 3. Access Dashboard

- **Frontend:** http://localhost:9999 (main dashboard)
- **Backend API:** http://localhost:9000/api (REST endpoints)
- **Backend Health:** http://localhost:9000/health
- **WebSocket:** ws://localhost:9000 (real-time updates)

---

## Features

### 📊 Service Health Panel

Real-time status of all 14 services:
- ✓ Ollama (port 11434)
- ✓ Open WebUI (port 3000)
- ✓ Orchestrator (port 8788)
- ✓ n8n (port 5678)
- ✓ Tools API (port 8765)
- ✓ MCP Toolkit (port 8766)
- ✓ Chroma (port 8001)
- ✓ Tika (port 9998)
- ✓ MinIO (port 9000)
- ✓ WAHA (port 3001)
- ✓ Prometheus (port 9090)
- ✓ Grafana (port 3002)
- ✓ Loki (port 3100)
- ✓ PostGraphile (port 5000)

**Updates:** Every 10 seconds via WebSocket

### 🧠 Models Management

- List all pulled models
- View model sizes
- Pull new models on-demand
- Select active model for chat
- Support for:
  - llama3.2:3b (default reasoning)
  - qwen2.5-coder:7b (coding tasks)
  - nomic-embed-text (RAG embeddings)

### 💬 Chat Interface

- Direct LLM interaction
- Model selection dropdown
- Multi-turn conversation
- Real-time streaming responses
- Context preservation

### 🛠️ Tools Browser

All business tools in one place:
- Shopify (inventory, orders)
- PostNL (shipping tracking)
- DHL Express (logistics)
- FedEx (package tracking)
- Microsoft 365 (calendar, email)
- Enreach CRM (customer data)
- Custom integrations

**Discovery:** Auto-load from Tools API endpoint

### ⚙️ Workflows (n8n)

- List all configured workflows
- Execute workflows directly
- Pass parameters to workflows
- Monitor execution status
- Link to n8n editor (port 5678)

### 🌐 Browser Automation

- Navigate to URLs
- Click elements (CSS selector)
- Extract page content
- Take screenshots
- Full browser control via API

### 🔍 RAG & Vector DB (Chroma)

- Embed documents
- Query semantic search
- Collections management
- Integration with Open WebUI

### 📈 Monitoring & Metrics

**Prometheus (port 9090):**
- Query metrics
- PromQL support
- Custom dashboards

**Grafana (port 3002):**
- Pre-built dashboards
- Real-time visualization
- Alert management

**Loki (port 3100):**
- Log aggregation
- Label-based queries
- LogQL support

### 📦 Object Storage (MinIO)

- Browse buckets
- Upload/download files
- S3-compatible API

### 📊 Data (PostGraphile)

- GraphQL endpoint
- Database query interface
- Auto-generated schema

---

## API Endpoints

### Health & Status

```
GET /health                    → Service health
GET /api/health                → Same as above
GET /api/services/health       → All services status
GET /api/dashboard/summary     → Full summary
```

### Ollama

```
GET /api/ollama/models         → List models
POST /api/ollama/pull          → Pull new model
POST /api/ollama/generate      → Generate text
```

### Orchestrator

```
GET /api/orchestrator/health   → Orchestrator status
POST /api/orchestrator/plan    → Create plan
POST /api/orchestrator/execute → Execute plan
```

### Chat

```
POST /api/chat                 → Chat with LLM
```

### Tools

```
GET /api/tools/available       → List tools
POST /api/tools/execute        → Execute tool
```

### Workflows

```
GET /api/workflows             → List n8n workflows
POST /api/workflows/execute    → Run workflow
```

### Browser

```
POST /api/browser/navigate     → Open URL
POST /api/browser/click        → Click element
```

### RAG

```
POST /api/rag/embed            → Embed text
POST /api/rag/query            → Vector search
```

### Documents

```
POST /api/documents/extract    → Extract from file
```

### Monitoring

```
GET /api/metrics/prometheus    → Query metrics
GET /api/logs/query            → Query logs
```

### GraphQL

```
POST /api/graphql              → GraphQL query
```

---

## WebSocket Connection

Real-time health updates via WebSocket:

```javascript
const ws = new WebSocket('ws://localhost:9000');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'health') {
    console.log('Service status:', data.data);
  }
};
```

Message format:
```json
{
  "type": "health",
  "data": {
    "ollama": { "status": "ok", "statusCode": 200 },
    "webui": { "status": "ok", "statusCode": 200 },
    ...
  }
}
```

---

## Configuration

### Backend Environment Variables

```yaml
# Service URLs
OLLAMA_URL: http://ollama-lenovo:11434
WEBUI_URL: http://webui-lenovo:8080
ORCHESTRATOR_URL: http://agentics-orch-lenovo:3001
N8N_URL: http://n8n:5678
TOOLS_API_URL: http://agentic-tools-lenovo:3001
MCP_URL: http://agentics-mcp-lenovo:8000
BROWSER_URL: http://browser-use-lenovo:8787
CHROMA_URL: http://chroma-lenovo:8000
TIKA_URL: http://tika-lenovo:9998
MINIO_URL: http://minio-lenovo:9000
WAHA_URL: http://waha-lenovo:3000
PROMETHEUS_URL: http://prometheus-lenovo:9090
GRAFANA_URL: http://grafana-lenovo:3000
LOKI_URL: http://loki-lenovo:3100
POSTGRAPHILE_URL: http://postgraphile-lenovo:5000

# API Keys
N8N_API_KEY: your-api-key

# Runtime
NODE_ENV: production
PORT: 9000
```

### Frontend Environment Variables

```yaml
REACT_APP_API_URL: http://localhost:9000
REACT_APP_WEBUI_URL: http://localhost:3000
REACT_APP_ORCHESTRATOR_URL: http://localhost:8788
```

---

## File Structure

```
agentics-unified-dashboard/
├── backend/
│   ├── server.js              # Express API + WebSocket
│   ├── package.json           # Dependencies
│   ├── Dockerfile             # Node.js image
│   └── .env.example           # Config template
├── frontend/
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── App.jsx            # Main React component
│   │   ├── App.css            # Styles
│   │   └── index.js
│   ├── package.json           # Dependencies
│   ├── Dockerfile             # Nginx + React build
│   └── nginx.conf             # Nginx config
└── docker-compose.override.yml
```

---

## Styling

Modern dark theme with:
- Neon cyan/blue (#00d4ff) accent colors
- Green success indicators (#00ff88)
- Red error states (#ff4444)
- Smooth transitions & animations
- Responsive grid layout
- WebSocket-driven real-time updates

### Color Scheme

```
Background:  #0f0f1e (dark navy)
Border:      #2d2d44 (grey)
Accent:      #00d4ff (cyan)
Success:     #00ff88 (green)
Error:       #ff4444 (red)
Text:        #e0e0e0 (light grey)
```

---

## Troubleshooting

### Dashboard Not Loading

```powershell
# Check backend
curl http://localhost:9000/health

# Check frontend
curl http://localhost:9999

# Check compose
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  -f docker-compose.unified-dashboard.override.yml \
  ps
```

### Services Showing Unhealthy

```powershell
# Check specific service
docker logs unified-dashboard-backend-lenovo

# Verify service URLs
docker exec unified-dashboard-backend-lenovo \
  curl -s http://ollama-lenovo:11434/api/tags
```

### WebSocket Connection Failed

```powershell
# Check WebSocket port
netstat -ano | findstr :9000

# Restart backend
docker restart unified-dashboard-backend-lenovo
```

### Frontend Cannot Connect to Backend

```powershell
# Check network
docker network inspect agentics_agentnet

# Verify Nginx config
docker exec unified-dashboard-frontend-lenovo cat /etc/nginx/conf.d/default.conf

# Restart frontend
docker restart unified-dashboard-frontend-lenovo
```

---

## Performance

### Resource Usage

| Component | CPU | Memory |
|-----------|-----|--------|
| Backend | 2.0 cores | 512MB |
| Frontend | 1.0 cores | 256MB |
| Total | 3.0 cores | 768MB |

### Health Check Interval

- **WebSocket updates:** Every 10 seconds
- **Service timeout:** 5 seconds
- **Max parallel checks:** 14 services

---

## Next Steps

1. **Access Dashboard:** http://localhost:9999
2. **Monitor Services:** Watch real-time health
3. **Test Chat:** Send messages via chat panel
4. **Execute Tools:** Try business tools
5. **Run Workflows:** Execute n8n workflows
6. **Scale:** Add more services to orchestration

---

## Integration Points

The dashboard connects to ALL these services:

✅ Ollama (LLM inference)  
✅ Open WebUI (chat UI)  
✅ Agentics Orchestrator (agent control)  
✅ n8n (workflows)  
✅ Business Tools API (integrations)  
✅ MCP Toolkit (capabilities)  
✅ Browser Automation (web scraping)  
✅ Chroma (vector DB)  
✅ Tika (document extraction)  
✅ MinIO (object storage)  
✅ WAHA (messaging)  
✅ Prometheus (metrics)  
✅ Grafana (dashboards)  
✅ Loki (logs)  
✅ PostGraphile (GraphQL)  

**Total:** 15 integrated services in ONE dashboard

---

## Summary

The **Unified Dashboard** is a complete control center for the Agentics stack:

- 🟢 **All services monitored** (real-time)
- 💬 **Direct chat** with LLMs
- 🛠️ **Tool discovery & execution**
- ⚙️ **Workflow automation**
- 🌐 **Browser control**
- 📊 **Metrics & monitoring**
- 🔍 **RAG & search**
- 📦 **Data management**

**Status:** Ready to deploy on Lenovo i9

**Next:** `docker compose -f docker-compose.yml -f docker-compose.lenovo-i9-cpu-npu.override.yml -f docker-compose.unified-dashboard.override.yml up -d`
