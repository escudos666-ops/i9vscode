# Lenovo i9 Agentics Stack — Deliverables Summary

**Status:** ✓ Complete  
**Date:** 2025  
**Target:** Lenovo i9 CPU-first, Windows Docker Desktop  
**Strategy:** Phase 1 CPU-only, Phase 2+ optional NPU via OpenVINO

---

## Overview

A complete, production-ready Agentics/Open WebUI stack for Lenovo i9 systems with:
- ✓ CPU-only inference (no NVIDIA/CUDA)
- ✓ Intel NPU deferred to Phase 2+ (optional OpenVINO sidecar)
- ✓ Stable Docker-first architecture
- ✓ PowerShell automation & health checks
- ✓ Full documentation & troubleshooting guides
- ✓ Correct network (`agentics_agentnet`), ports (3000, 8788, etc.), and models (llama3.2:3b, qwen2.5-coder:7b, nomic-embed-text)

---

## Deliverable Files

### 1. Docker Compose Configuration

**File:** `docker-compose.lenovo-i9-cpu-npu.override.yml`

**Purpose:** Complete Agentics stack override for Lenovo i9 CPU-only operation

**Contains:**
- 5 core services: postgres, ollama, open-webui, agent-dashboard, agentics-orchestrator
- 10+ optional services: n8n, tools API, browser automation, MCP, data backends (Chroma, Tika, MinIO), monitoring (Prometheus, Grafana, Loki, cAdvisor), PostGraphile
- Network: `agentics_agentnet` (172.24.0.0/16)
- All ports correctly mapped (3000, 8787, 8788, 11434, 5678, 5432, etc.)
- Environment: CPU-optimized Ollama (OLLAMA_NUM_PARALLEL=1, OLLAMA_KEEP_ALIVE=10m, OLLAMA_KV_CACHE_TYPE=q8_0)
- No NVIDIA, no CUDA, no runtime: nvidia directives
- Resource limits: Ollama 16GB, WebUI 6GB, Orchestrator 2GB, others appropriately scaled

**Usage:**
```powershell
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  up -d postgres-lenovo ollama-lenovo webui-lenovo
```

---

### 2. PowerShell Start Script

**File:** `start-agentics-lenovo-i9-npu.ps1`

**Purpose:** Automated stack startup with model pulls, health checks, and logging

**Features:**
- Pre-flight checks (Docker, Compose, files)
- Stop existing containers cleanly
- Start core services (postgres, ollama, webui)
- Auto-pull required models (llama3.2:3b, qwen2.5-coder:7b, nomic-embed-text)
- Start orchestrator & dashboard
- Run health checks (3000, 8788, 11434)
- Color-coded output with emojis
- Help documentation inline

**Options:**
- `-OnlyUp` — Start services without model pulls
- `-SkipModels` — Skip model pulls entirely
- `-OnlyDown` — Stop services only
- `-SkipPull` — Skip Docker image pulls
- `-Healthcheck` — Run health checks only
- `-Logs` — Show container logs

**Usage:**
```powershell
.\start-agentics-lenovo-i9-npu.ps1          # Full start
.\start-agentics-lenovo-i9-npu.ps1 -SkipModels  # Fast start
.\start-agentics-lenovo-i9-npu.ps1 -OnlyDown    # Stop
```

---

### 3. Verification Script

**File:** `verify-lenovo-i9-setup.ps1`

**Purpose:** Pre-flight checks before startup

**Checks:**
- Docker installation & daemon running
- Docker Compose availability
- Compose files exist & accessible
- Start script present
- .env files present (warns if defaults are used)
- Network configuration
- Port availability (3000, 8787, 8788, 11434, 5678, 5432, etc.)
- Compose file validation
- Hardware detection (Lenovo i9 processor)

**Usage:**
```powershell
.\verify-lenovo-i9-setup.ps1
.\verify-lenovo-i9-setup.ps1 -Verbose  # Detailed output
.\verify-lenovo-i9-setup.ps1 -SkipPortCheck  # Skip port checks
```

---

### 4. Environment Template

**File:** `.env.lenovo`

**Purpose:** Configuration template for credentials, service URLs, and settings

**Sections:**
- Core database (PostgreSQL credentials)
- Ollama (CPU-only settings: OLLAMA_NUM_PARALLEL=1, OLLAMA_KEEP_ALIVE=10m, CUDA_VISIBLE_DEVICES=-1)
- Open WebUI (secrets, RAG, function calling, context length)
- Agentics Orchestrator (models, service URLs, Docker socket)
- N8N (workflow automation)
- Agentic Business Tools API (shipping, Shopify, Microsoft, Enreach)
- Browser automation (VNC)
- Observability (Grafana password)
- MinIO (object storage)
- NPU Phase 2+ (placeholder for future OpenVINO settings)

**Usage:**
```powershell
# Copy template and fill in
cp .env.lenovo .env.lenovo.prod
# Edit .env.lenovo.prod with your credentials

# Use with compose
docker compose --env-file .env.lenovo.prod up
```

---

### 5. NPU Strategy & Roadmap

**File:** `LENOVO_I9_NPU_STRATEGY.md`

**Purpose:** Comprehensive guide for adding Intel NPU support via OpenVINO (Phase 2+)

**Phases:**
1. **Phase 1 (Current):** CPU-first Docker stack stable
2. **Phase 2:** Intel NPU hardware verification (Device Manager, drivers)
3. **Phase 3:** OpenVINO installation on Windows host
4. **Phase 4:** Model conversion & local NPU testing
5. **Phase 5:** Docker OpenVINO sidecar service
6. **Phase 5b/5c:** WebUI & Orchestrator NPU backend integration

**Contains:**
- Detailed instructions for each phase
- Windows Device Manager NPU checks
- OpenVINO download & installation
- Model conversion with optimum-intel
- Docker OpenVINO sidecar Dockerfile & API server
- Integration examples for Open WebUI & Orchestrator
- Troubleshooting: NPU not detected, Docker access issues, model conversion failures, slow inference
- Checkpoint criteria for moving between phases

**Key Rule:** Do not block Phase 1 on NPU. Complete Phase 1 (CPU stability), then assess Phase 2+ if more performance is needed.

---

### 6. Full Documentation

**File:** `README_LENOVO_I9.md`

**Purpose:** Complete user guide for the Lenovo i9 Agentics stack

**Sections:**
- Quick Start (3 steps: verify → start → access)
- Architecture diagram (Docker network, services, ports)
- File reference (all config & script files)
- Models (auto-pulled: llama3.2:3b, qwen2.5-coder:7b, nomic-embed-text)
- Configuration (CPU optimization, resource allocation)
- Troubleshooting (stack won't start, WebUI not responding, no models, port conflicts, high CPU, OOM)
- Health checks (manual endpoints, expected output)
- Next steps (Phase 1 checklist, Phase 2+ reference)
- Stopping the stack
- Support & resources

**Usage:** Primary reference document; linked from quick reference.

---

### 7. Quick Reference Card

**File:** `LENOVO_I9_QUICK_REF.md`

**Purpose:** One-page cheat sheet for rapid development

**Contains:**
- Pre-flight & start commands
- Service endpoints (ports, URLs)
- Models (auto-pulled)
- Health check one-liners
- Docker commands (status, logs, stats, network)
- Manual model pulls
- Troubleshooting quick fixes
- Configuration reference
- File reference
- NPU Phase reference (link to full strategy)
- Rules (never violate)
- Emergency stop

**Usage:** Keep in terminal, reference quickly during development.

---

## Service Port Allocation

| Port | Service | Container | Host | Purpose |
|------|---------|-----------|------|---------|
| 3000 | Open WebUI | 8080 | 3000 | Chat interface, LLM access |
| 8787 | Agent Dashboard | 3000 | 8787 | Agent monitoring & control |
| 8788 | Agentics Orchestrator | 3001 | 8788 | Agent orchestration API |
| 11434 | Ollama | 11434 | 11434 | LLM inference engine |
| 5678 | n8n | 3000 | 5678 | Workflow automation |
| 5432 | PostgreSQL | 5432 | 5432 | Persistent storage |
| 8765 | Tools API | 3001 | 8765 | Business tools (Shopify, shipping, etc.) |
| 8001 | Chroma | 8000 | 8001 | Vector database for RAG |
| 9998 | Tika | 9998 | 9998 | Document extraction |
| 9000 | MinIO | 9000 | 9000 | Object storage (S3-compatible) |
| 9001 | MinIO Console | 9001 | 9001 | MinIO management UI |
| 3001 | WAHA | 3000 | 3001 | WhatsApp-like messaging |
| 9090 | Prometheus | 9090 | 9090 | Metrics collection |
| 3002 | Grafana | 3000 | 3002 | Monitoring dashboards |
| 3100 | Loki | 3100 | 3100 | Log aggregation |
| 8089 | cAdvisor | 8080 | 8089 | Container metrics |
| 5000 | PostGraphile | 5000 | 5000 | GraphQL API over PostgreSQL |

**Network:** `agentics_agentnet` (172.24.0.0/16)

---

## Environment Configuration

### CPU Optimization (Phase 1)

```yaml
environment:
  OLLAMA_NUM_PARALLEL: "1"            # Single model at a time
  OLLAMA_NUM_THREAD: "0"              # Auto-detect all cores
  OLLAMA_KEEP_ALIVE: "10m"            # 10 min before unload
  OLLAMA_KV_CACHE_TYPE: "q8_0"        # Quantized cache
  CUDA_VISIBLE_DEVICES: "-1"          # Disable NVIDIA
  NVIDIA_VISIBLE_DEVICES: "void"      # Extra safety
  OLLAMA_DEFAULT_MODEL: "llama3.2:3b"
```

### Resource Allocation

| Service | CPU | Memory | Justification |
|---------|-----|--------|---------------|
| Ollama | 16.0 | 16GB | LLM inference; i9 has 24+ cores |
| Open WebUI | 4.0 | 6GB | Web UI + RAG processing |
| Orchestrator | 4.0 | 2GB | Agent planning & scheduling |
| Dashboard | 2.0 | 512MB | UI service |
| PostgreSQL | 2.0 | 2GB | Database; multiple tables |
| n8n | 2.0 | 1GB | Workflow engine |
| Browser | 4.0 | 2GB | Chromium automation |
| Others | 1.0–2.0 | 256MB–512MB | Supporting services |

**Total:** ~40 CPU cores, ~30GB RAM (scalable based on i9 variant)

---

## Models (Auto-Pulled)

| Model | Size | Purpose | Provider | Format |
|-------|------|---------|----------|--------|
| `llama3.2:3b` | 2.5GB | Main reasoning & chat | Meta (Ollama) | GGUF |
| `qwen2.5-coder:7b` | 4.5GB | Coding tasks & debugging | Alibaba (Ollama) | GGUF |
| `nomic-embed-text` | 274MB | RAG embeddings | Nomic (Ollama) | GGUF |

**Pull Command:**
```powershell
docker exec ollama-lenovo ollama pull llama3.2:3b
docker exec ollama-lenovo ollama pull qwen2.5-coder:7b
docker exec ollama-lenovo ollama pull nomic-embed-text
```

---

## Network Architecture

```
Host Network (Windows Docker Desktop)
├─ Port 3000 → WebUI:8080
├─ Port 8787 → Dashboard:3000
├─ Port 8788 → Orchestrator:3001
├─ Port 11434 → Ollama:11434
├─ Port 5678 → n8n:3000
├─ Port 5432 → PostgreSQL:5432
└─ [15+ other services]
    ↓
Docker Desktop (WSL2/Hyper-V)
    ↓
agentics_agentnet (172.24.0.0/16)
├─ postgres-lenovo (172.24.0.2)
├─ ollama-lenovo (172.24.0.3)
├─ webui-lenovo (172.24.0.4)
├─ agent-dashboard-lenovo (172.24.0.5)
├─ agentics-orch-lenovo (172.24.0.6)
├─ n8n (172.24.0.7)
├─ agentic-tools-lenovo (172.24.0.8)
├─ browser-use-lenovo (172.24.0.9)
├─ agentics-mcp-lenovo (172.24.0.10)
├─ [Optional services...]
└─ [Custom bridges]
```

---

## Health Check Endpoints

All endpoints should return 2xx on healthy stack:

```powershell
# WebUI
Invoke-RestMethod "http://127.0.0.1:3000/api/version"

# Orchestrator
Invoke-RestMethod "http://127.0.0.1:8788/health"

# Ollama
Invoke-RestMethod "http://127.0.0.1:11434/api/tags"

# Dashboard
Invoke-RestMethod "http://127.0.0.1:8787"

# n8n
Invoke-RestMethod "http://127.0.0.1:5678/health"

# PostgreSQL
docker exec postgres-lenovo psql -U webui -d openwebui -c "SELECT 1;"

# Container Status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## Key Rules (Non-Negotiable)

1. ✓ No NVIDIA, CUDA, runtime: nvidia, gpus directives
2. ✓ Use `agentics_agentnet` network (not `ai-net`)
3. ✓ Keep Open WebUI on port 3000
4. ✓ Keep Agent Dashboard on port 8787
5. ✓ Keep Orchestrator on port 8788 (maps container 3001)
6. ✓ Keep WAHA on port 3001 (reserved)
7. ✓ Use CPU-friendly models first (llama3.2:3b, qwen2.5-coder:7b)
8. ✓ Do not destructively edit original docker-compose.yml
9. ✓ Always use override file: `-f docker-compose.lenovo-i9-cpu-npu.override.yml`
10. ✓ Use PowerShell scripts (Windows environment)
11. ✓ Defer NPU to Phase 2+ (do not block Phase 1)
12. ✓ Do not change working Agentics Web Browser tool settings
13. ✓ Browser-use iframe is separate from OpenAPI browse tool
14. ✓ Be honest when services are unverified

---

## One-Shot Start Sequence

```powershell
# 1. Navigate to project root
cd C:\DeerpShit\Agentics

# 2. Verify setup
.\verify-lenovo-i9-setup.ps1

# 3. Start stack
.\start-agentics-lenovo-i9-npu.ps1

# 4. Wait ~3-5 minutes for models to pull

# 5. Access services
# Open WebUI: http://localhost:3000
# Dashboard: http://localhost:8787
# Orchestrator: http://localhost:8788
```

---

## Troubleshooting Flow

```
Is Docker running?
├─ No → Start Docker Desktop
└─ Yes ↓

Does verify script pass?
├─ No → Fix issues reported
└─ Yes ↓

Does 'docker ps' show containers?
├─ No → Run .\start-agentics-lenovo-i9-npu.ps1
└─ Yes ↓

Is WebUI responding?
├─ No → docker logs webui-lenovo
└─ Yes ↓

Does Ollama have models?
├─ No → docker exec ollama-lenovo ollama pull llama3.2:3b
└─ Yes ↓

✓ Stack is healthy! Check http://localhost:3000
```

---

## Next Phases (When Ready)

### Phase 2: NPU Verification
- See `LENOVO_I9_NPU_STRATEGY.md` Phase 2
- Verify NPU in Windows Device Manager
- Update Intel drivers if needed

### Phase 3–5: OpenVINO Integration
- See `LENOVO_I9_NPU_STRATEGY.md` Phases 3–5
- Install OpenVINO on Windows host
- Convert small models (TinyLlama 1.1B)
- Create Docker OpenVINO sidecar service
- Connect WebUI/Orchestrator to NPU backend

**Do not start Phase 2 until Phase 1 is stable.**

---

## Summary

**What You Get:**
- ✓ Stable, CPU-only Agentics/Open WebUI stack on Lenovo i9
- ✓ 5 core services + 10+ optional services pre-configured
- ✓ Correct network (agentics_agentnet), ports (3000, 8788, etc.), models (llama3.2:3b, qwen2.5-coder:7b, nomic-embed-text)
- ✓ PowerShell automation (start, stop, health check)
- ✓ Pre-flight verification script
- ✓ Comprehensive NPU roadmap (Phase 2+)
- ✓ Full documentation & troubleshooting
- ✓ Quick reference card

**What's NOT Included (Deferred):**
- NPU/OpenVINO integration (Phase 2+, optional)
- Production secrets management (use .env.lenovo)
- GPU support (intentionally omitted)
- Kubernetes/Swarm orchestration (Docker Compose only)

**Status:** Ready to deploy on Lenovo i9 with Windows Docker Desktop.

---

## Files at a Glance

```
C:\DeerpShit\Agentics\
├── docker-compose.yml                           (original, do not edit)
├── docker-compose.lenovo-i9-cpu-npu.override.yml (NEW — use this)
├── start-agentics-lenovo-i9-npu.ps1            (NEW — start/stop script)
├── verify-lenovo-i9-setup.ps1                  (NEW — pre-flight checks)
├── .env.lenovo                                 (NEW — config template)
├── README_LENOVO_I9.md                         (NEW — full guide)
├── LENOVO_I9_NPU_STRATEGY.md                   (NEW — Phase 2+ roadmap)
├── LENOVO_I9_QUICK_REF.md                      (NEW — one-page cheat sheet)
└── [other project files...]
```

**To start:** Run `.\verify-lenovo-i9-setup.ps1`, then `.\start-agentics-lenovo-i9-npu.ps1`
