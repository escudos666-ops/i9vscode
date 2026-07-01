# Agentics Lenovo i9 CPU-First Stack

A **stable, CPU-only** implementation of the Agentics/Open WebUI stack on Lenovo i9 systems, with Intel NPU support deferred to Phase 2+ as an optional OpenVINO sidecar.

## Quick Start

### 1. Verify Setup

```powershell
cd C:\DeerpShit\Agentics
.\verify-lenovo-i9-setup.ps1
```

This checks:
- Docker & Docker Compose installed
- Compose files present
- Network configuration
- Port availability
- Hardware (Lenovo i9)

### 2. Start Stack

```powershell
.\start-agentics-lenovo-i9-npu.ps1
```

This will:
1. Stop any existing containers
2. Start core services (Postgres, Ollama, WebUI)
3. Pull required Ollama models
4. Start orchestrator and dashboard
5. Run health checks

### 3. Access Services

| Service | URL | Purpose |
|---------|-----|---------|
| **Open WebUI** | http://localhost:3000 | Chat interface with LLM |
| **Agent Dashboard** | http://localhost:8787 | Agent monitoring & control |
| **Orchestrator** | http://localhost:8788 | Agent orchestration API |
| **Ollama** | http://localhost:11434 | LLM inference engine |
| **n8n** | http://localhost:5678 | Workflow automation |
| **PostgreSQL** | localhost:5432 | Persistent storage |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Windows Docker Desktop (WSL2/Hyper-V)                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ agentics_agentnet (172.24.0.0/16)                       │   │
│  │                                                         │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │   │
│  │  │ Open WebUI   │ │ Ollama       │ │ PostgreSQL   │   │   │
│  │  │ 3000:8080    │ │ 11434:11434  │ │ 5432:5432    │   │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘   │   │
│  │                         ▲                               │   │
│  │  ┌──────────────┐       │      ┌──────────────┐       │   │
│  │  │ Dashboard    │───────┼──────│ Orchestrator │       │   │
│  │  │ 8787:3000    │       │      │ 8788:3001    │       │   │
│  │  └──────────────┘       │      └──────────────┘       │   │
│  │                         │                               │   │
│  │  ┌──────────────┐       │      ┌──────────────┐       │   │
│  │  │ n8n          │       │      │ Tools API    │       │   │
│  │  │ 5678:3000    │       └──────│ 8765:3001    │       │   │
│  │  └──────────────┘              └──────────────┘       │   │
│  │                                                         │   │
│  │  [Other services: Chroma, Tika, MinIO, Prometheus...] │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Environment (Phase 1):                                        │
│  - OLLAMA_NUM_PARALLEL=1 (no thrashing)                       │
│  - OLLAMA_NUM_THREAD=0 (auto-detect)                          │
│  - OLLAMA_KEEP_ALIVE=10m                                      │
│  - OLLAMA_KV_CACHE_TYPE=q8_0                                  │
│  - CUDA_VISIBLE_DEVICES=-1 (no NVIDIA)                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

  ↓
  
Phase 2+ (Optional NPU):
┌─────────────────────────────────────────────────────────────────┐
│ Windows Host (Native)                                           │
│                                                                 │
│  Intel NPU (Device Manager)                                     │
│         ↓                                                        │
│  OpenVINO Runtime (Phase 3)                                     │
│         ↓                                                        │
│  Model Conversion Tool (Phase 4)                                │
│         ↓                                                        │
│  OpenVINO HTTP Service (Phase 5)                                │
│         ↓                                                        │
│  Docker Container → Connect (Phase 5)                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files

### Core Compose Files

**`docker-compose.yml`**
- Original RTX/GPU stack configuration
- Do NOT edit for Lenovo i9

**`docker-compose.lenovo-i9-cpu-npu.override.yml`** (NEW)
- CPU-only Ollama config
- Lenovo i9-specific resource limits
- agentics_agentnet network
- No NVIDIA references
- All required services pre-configured
- Use with: `docker compose -f docker-compose.yml -f docker-compose.lenovo-i9-cpu-npu.override.yml up`

### Start Scripts

**`start-agentics-lenovo-i9-npu.ps1`** (NEW)
- PowerShell automation for full stack startup
- Pulls required Ollama models
- Runs health checks
- Usage: `.\start-agentics-lenovo-i9-npu.ps1`

**`verify-lenovo-i9-setup.ps1`** (NEW)
- Pre-flight checks before startup
- Validates Docker, compose files, ports, network
- Usage: `.\verify-lenovo-i9-setup.ps1`

### Configuration

**`.env.lenovo`** (NEW)
- Template for environment variables
- Database credentials
- Service URLs
- API keys (left blank for testing)
- Copy and fill in as needed: `docker compose --env-file .env.lenovo up`

### Documentation

**`LENOVO_I9_NPU_STRATEGY.md`** (NEW)
- Detailed NPU integration roadmap (6 phases)
- Windows NPU driver verification
- OpenVINO installation & model conversion
- Docker OpenVINO sidecar setup
- Troubleshooting guide

---

## Models

### Default (Phase 1 — CPU)

| Model | Size | Purpose | Status |
|-------|------|---------|--------|
| `llama3.2:3b` | 2.5GB | Main reasoning/chat | Auto-pulled on start |
| `qwen2.5-coder:7b` | 4.5GB | Coding tasks | Auto-pulled on start |
| `nomic-embed-text` | 274MB | RAG embeddings | Auto-pulled on start |

### With NPU Bridge (Phase 5+)

- TinyLlama 1.1B (converted to OpenVINO IR)
- Or custom models converted via optimum-intel

---

## Configuration

### CPU Optimization

The override compose file sets these for CPU-only inference:

```yaml
environment:
  OLLAMA_NUM_PARALLEL: "1"        # No CPU oversubscription
  OLLAMA_NUM_THREAD: "0"          # Auto-detect (all cores)
  OLLAMA_KEEP_ALIVE: "10m"        # Keep model in memory
  OLLAMA_KV_CACHE_TYPE: "q8_0"    # Quantized cache (lower VRAM)
  CUDA_VISIBLE_DEVICES: "-1"      # Disable NVIDIA
  NVIDIA_VISIBLE_DEVICES: "void"  # Extra safety
```

### Resource Allocation

| Service | CPU | Memory | Purpose |
|---------|-----|--------|---------|
| Ollama | 16.0 | 16GB | LLM inference (i9 has 24+ cores) |
| Open WebUI | 4.0 | 6GB | Web interface + RAG |
| Orchestrator | 4.0 | 2GB | Agent control |
| Dashboard | 2.0 | 512MB | Agent monitoring |
| PostgreSQL | 2.0 | 2GB | Data persistence |
| Others | 1.0–2.0 | 256MB–1GB | Supporting services |

---

## Troubleshooting

### Stack Won't Start

**Problem:** `docker compose up` fails

**Solution:**
```powershell
# 1. Run verification
.\verify-lenovo-i9-setup.ps1

# 2. Check Docker daemon
docker ps

# 3. Stop and clean
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  down -v

# 4. Prune (careful: removes unused images/volumes)
docker system prune -f

# 5. Try again
.\start-agentics-lenovo-i9-npu.ps1
```

### WebUI Not Responding

**Problem:** `http://localhost:3000` times out

**Solution:**
```powershell
# Check container logs
docker logs webui-lenovo

# Verify Ollama is running
Invoke-RestMethod "http://127.0.0.1:11434/api/tags"

# Verify database
docker logs postgres-lenovo

# Check network
docker network inspect agentics_agentnet

# Restart WebUI
docker restart webui-lenovo
```

### Ollama Has No Models

**Problem:** `http://localhost:11434/api/tags` returns empty

**Solution:**
```powershell
# Check if models are pulling
docker exec ollama-lenovo ollama list

# If empty, pull manually
docker exec ollama-lenovo ollama pull llama3.2:3b
docker exec ollama-lenovo ollama pull nomic-embed-text

# Watch progress
docker logs -f ollama-lenovo
```

### Port Already in Use

**Problem:** `Bind for 0.0.0.0:3000 failed: port is already allocated`

**Solution:**
```powershell
# Find what's using port 3000
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | 
  Select-Object OwningProcess | 
  ForEach-Object { Get-Process -Id $_.OwningProcess }

# Stop the process or change port in compose override

# Or use different host port
# Edit docker-compose.lenovo-i9-cpu-npu.override.yml:
# ports:
#   - "3001:8080"  # Changed from 3000
```

### High CPU Usage

**Problem:** CPU at 100% even when idle

**Solution:**
```powershell
# Reduce Ollama parallelism
# Edit .env.lenovo or compose:
# OLLAMA_NUM_PARALLEL=1  (should be 1)
# OLLAMA_KEEP_ALIVE=5m   (reduce from 10m)

# Reduce WebUI workers
# UVICORN_WORKERS=1

# Restart services
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  restart ollama-lenovo webui-lenovo
```

### Out of Memory

**Problem:** Containers crashing with exit code 137 (OOM)

**Solution:**
```powershell
# Check memory usage
docker stats --no-stream

# Increase Docker Desktop memory:
# 1. Docker Desktop → Settings → Resources
# 2. Increase "Memory" to 20GB+ (if available)
# 3. Restart Docker

# Or reduce model sizes:
# OLLAMA_KEEP_ALIVE=2m  (unload faster)
# OLLAMA_NUM_PARALLEL=0 (run models sequentially)
```

---

## Health Checks

### Full Health Check

```powershell
# Run via script
.\start-agentics-lenovo-i9-npu.ps1 -Healthcheck

# Or manual
Invoke-RestMethod "http://127.0.0.1:3000/api/version"
Invoke-RestMethod "http://127.0.0.1:8788/health"
Invoke-RestMethod "http://127.0.0.1:11434/api/tags"
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Expected Output

```
WebUI:        Healthy ✓
Orchestrator: {"status": "ok"}
Ollama:       {"models": [{"name": "llama3.2:3b"}, ...]}
Containers:   All running
```

---

## Next Steps

### Phase 1 (Current)

- ✓ CPU-first stack stable
- ✓ Models pullable and inference working
- ✓ Open WebUI accessible at http://localhost:3000
- ✓ Agent Dashboard accessible at http://localhost:8787
- ✓ Orchestrator healthy at http://localhost:8788

### Phase 2 (When Ready)

See `LENOVO_I9_NPU_STRATEGY.md` for NPU integration roadmap.

---

## Stopping the Stack

```powershell
# Normal stop (keeps data)
.\start-agentics-lenovo-i9-npu.ps1 -OnlyDown

# Or manual
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  down

# Full clean (removes data, volumes)
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  down -v
```

---

## Support

For issues:
1. Check `LENOVO_I9_NPU_STRATEGY.md` troubleshooting section
2. Review Docker logs: `docker logs <container-name>`
3. Verify health: `.\verify-lenovo-i9-setup.ps1`
4. Run compose validation: `docker compose config`

---

## Summary

This is a **CPU-first, production-ready Agentics stack** on Lenovo i9 with:
- ✓ No NVIDIA/CUDA dependencies
- ✓ Intel NPU support deferred to optional Phase 2+
- ✓ Stable Ollama with llama3.2:3b, qwen2.5-coder:7b, nomic-embed-text
- ✓ Full agent orchestration & dashboard
- ✓ PowerShell automation & health checks
- ✓ Docker-first, no special host setup required

Ready to start: `.\start-agentics-lenovo-i9-npu.ps1`
