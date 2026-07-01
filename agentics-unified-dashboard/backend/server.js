// ============================================================================
// AGENTICS UNIFIED DASHBOARD — BACKEND + FRONTEND SERVER
// ============================================================================
// Single Node.js process:
//  - Serves static HTML/CSS/JS dashboard on /
//  - REST API gateway to all stack services on /api/*
//  - WebSocket server for real-time health updates
// ============================================================================

const express = require('express');
const http    = require('http');
const WebSocket = require('ws');
const cors    = require('cors');
const axios   = require('axios');
const path    = require('path');

const app    = express();
const server = http.createServer(app);
const wss    = new WebSocket.Server({ server });

// ============================================================================
// SERVICE MAP  — reads from env so compose can override per machine
// ============================================================================
const SVC = {
  ollama:        process.env.OLLAMA_URL        || 'http://ollama-service:11434',
  webui:         process.env.WEBUI_URL         || 'http://webui-service:8080',
  orchestrator:  process.env.ORCHESTRATOR_URL  || 'http://agentics-orch-lenovo:3001',
  n8n:           process.env.N8N_URL           || 'http://n8n:5678',
  toolsApi:      process.env.TOOLS_API_URL     || 'http://agentic-tools-lenovo:3001',
  mcp:           process.env.MCP_URL           || 'http://agentics-mcp-lenovo:8000',
  chroma:        process.env.CHROMA_URL        || 'http://chroma-lenovo:8000',
  tika:          process.env.TIKA_URL          || 'http://tika-lenovo:9998',
  minio:         process.env.MINIO_URL         || 'http://minio-lenovo:9000',
  waha:          process.env.WAHA_URL          || 'http://waha-lenovo:3000',
  prometheus:    process.env.PROMETHEUS_URL    || 'http://prometheus-lenovo:9090',
  grafana:       process.env.GRAFANA_URL       || 'http://grafana-lenovo:3000',
  loki:          process.env.LOKI_URL          || 'http://loki-lenovo:3100',
  postgraphile:  process.env.POSTGRAPHILE_URL  || 'http://postgraphile-lenovo:5000',
};

const PORT = process.env.PORT || 9000;

// ============================================================================
// MIDDLEWARE
// ============================================================================
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// ============================================================================
// HELPERS
// ============================================================================
async function probe(name, url, path = '/health') {
  try {
    const r = await axios.get(url + path, { timeout: 4000 });
    return { name, url, status: 'ok', code: r.status };
  } catch (e) {
    return { name, url, status: 'error', code: e.response?.status || 0, error: e.message };
  }
}

async function allHealth() {
  const checks = await Promise.allSettled([
    probe('ollama',       SVC.ollama,       '/api/tags'),
    probe('webui',        SVC.webui,        '/health'),
    probe('orchestrator', SVC.orchestrator, '/health'),
    probe('n8n',          SVC.n8n,          '/healthz'),
    probe('tools-api',    SVC.toolsApi,     '/health'),
    probe('mcp',          SVC.mcp,          '/health'),
    probe('chroma',       SVC.chroma,       '/api/v1'),
    probe('tika',         SVC.tika,         '/status'),
    probe('minio',        SVC.minio,        '/minio/health/live'),
    probe('waha',         SVC.waha,         '/api/status'),
    probe('prometheus',   SVC.prometheus,   '/-/healthy'),
    probe('grafana',      SVC.grafana,      '/api/health'),
    probe('loki',         SVC.loki,         '/ready'),
    probe('postgraphile', SVC.postgraphile, '/graphql'),
  ]);
  return Object.fromEntries(
    checks.map(r => {
      const v = r.status === 'fulfilled' ? r.value : { name: '?', status: 'error', error: r.reason?.message };
      return [v.name, v];
    })
  );
}

// ============================================================================
// ROUTES — HEALTH
// ============================================================================
app.get('/health',            (_, res) => res.json({ status: 'ok', uptime: process.uptime() }));
app.get('/api/health',        (_, res) => res.json({ status: 'ok', uptime: process.uptime() }));

app.get('/api/services/health', async (_, res) => {
  const h = await allHealth();
  res.json({ services: h, ts: new Date().toISOString() });
});

app.get('/api/dashboard/summary', async (_, res) => {
  const [health, models] = await Promise.all([allHealth(), getModels()]);
  const vals = Object.values(health);
  res.json({
    ts: new Date().toISOString(),
    uptime: process.uptime(),
    services: { total: vals.length, healthy: vals.filter(s => s.status === 'ok').length, details: health },
    models:   { total: models.length, list: models },
  });
});

// ============================================================================
// ROUTES — OLLAMA
// ============================================================================
async function getModels() {
  try {
    const r = await axios.get(SVC.ollama + '/api/tags', { timeout: 5000 });
    return r.data.models || [];
  } catch { return []; }
}

app.get('/api/ollama/models',        async (_, res) => res.json({ models: await getModels() }));
app.get('/api/ollama/running',       async (_, res) => {
  try { const r = await axios.get(SVC.ollama + '/api/ps', { timeout: 5000 }); res.json(r.data); }
  catch (e) { res.json({ models: [], error: e.message }); }
});

app.post('/api/ollama/pull', async (req, res) => {
  const { model } = req.body;
  if (!model) return res.status(400).json({ error: 'model required' });
  res.json({ status: 'pulling', model });
  axios.post(SVC.ollama + '/api/pull', { name: model }, { timeout: 600000 })
       .catch(e => console.error('pull error:', e.message));
});

app.post('/api/ollama/generate', async (req, res) => {
  const { model, prompt } = req.body;
  if (!model || !prompt) return res.status(400).json({ error: 'model + prompt required' });
  try {
    const r = await axios.post(SVC.ollama + '/api/generate',
      { model, prompt, stream: false }, { timeout: 120000 });
    res.json(r.data);
  } catch (e) { res.status(502).json({ error: e.message }); }
});

app.post('/api/ollama/chat', async (req, res) => {
  const { model, messages } = req.body;
  if (!model || !messages) return res.status(400).json({ error: 'model + messages required' });
  try {
    const r = await axios.post(SVC.ollama + '/api/chat',
      { model, messages, stream: false }, { timeout: 120000 });
    res.json(r.data);
  } catch (e) { res.status(502).json({ error: e.message }); }
});

// ============================================================================
// ROUTES — ORCHESTRATOR
// ============================================================================
app.get('/api/orchestrator/health', async (_, res) => {
  try { const r = await axios.get(SVC.orchestrator + '/health', { timeout: 5000 }); res.json(r.data); }
  catch (e) { res.status(502).json({ error: e.message }); }
});

app.post('/api/orchestrator/chat', async (req, res) => {
  try {
    const r = await axios.post(SVC.orchestrator + '/api/chat', req.body, { timeout: 60000 });
    res.json(r.data);
  } catch (e) { res.status(502).json({ error: e.message }); }
});

// ============================================================================
// ROUTES — N8N WORKFLOWS
// ============================================================================
app.get('/api/workflows', async (_, res) => {
  try {
    const r = await axios.get(SVC.n8n + '/api/v1/workflows',
      { timeout: 5000, headers: { 'X-N8N-API-KEY': process.env.N8N_API_KEY || '' } });
    res.json(r.data);
  } catch (e) { res.status(502).json({ error: e.message, workflows: [] }); }
});

// ============================================================================
// ROUTES — TOOLS API
// ============================================================================
app.get('/api/tools', async (_, res) => {
  try {
    const r = await axios.get(SVC.toolsApi + '/api/tools', { timeout: 5000 });
    res.json(r.data);
  } catch (e) { res.status(502).json({ error: e.message, tools: [] }); }
});

// ============================================================================
// ROUTES — PROMETHEUS METRICS
// ============================================================================
app.get('/api/metrics', async (req, res) => {
  const q = req.query.query || 'up';
  try {
    const r = await axios.get(SVC.prometheus + '/api/v1/query', { params: { query: q }, timeout: 5000 });
    res.json(r.data);
  } catch (e) { res.status(502).json({ error: e.message }); }
});

// ============================================================================
// ROUTES — PROXY PASS-THROUGH (for iframes)
// ============================================================================
app.get('/api/urls', (_, res) => {
  res.json({
    webui:       'http://localhost:3000',
    dashboard:   'http://localhost:8787',
    orchestrator:'http://localhost:8788',
    n8n:         'http://localhost:5678',
    grafana:     'http://localhost:3002',
    minio:       'http://localhost:9001',
    prometheus:  'http://localhost:9090',
  });
});

// ============================================================================
// WEBSOCKET — push health every 8s
// ============================================================================
wss.on('connection', ws => {
  console.log('[ws] client connected');
  let alive = true;

  const push = async () => {
    if (!alive) return;
    try {
      const h = await allHealth();
      ws.send(JSON.stringify({ type: 'health', data: h, ts: Date.now() }));
    } catch {}
  };

  push(); // immediate first push
  const iv = setInterval(push, 8000);

  ws.on('close', () => { alive = false; clearInterval(iv); console.log('[ws] client disconnected'); });
  ws.on('error', () => { alive = false; clearInterval(iv); });
});

// ============================================================================
// SPA FALLBACK
// ============================================================================
app.get('*', (_, res) => res.sendFile(path.join(__dirname, 'public', 'index.html')));

// ============================================================================
// START
// ============================================================================
server.listen(PORT, () => {
  console.log(`\n🚀 Agentics Dashboard  →  http://localhost:${PORT}`);
  console.log(`📡 WebSocket           →  ws://localhost:${PORT}`);
  console.log(`📊 Services configured →  ${Object.keys(SVC).length}`);
  console.log(`🔗 Ollama              →  ${SVC.ollama}`);
  console.log(`🔗 WebUI               →  ${SVC.webui}\n`);
});
