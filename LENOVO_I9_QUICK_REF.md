# Lenovo i9 Agentics Stack — Quick Reference

## Pre-Flight

```powershell
cd C:\DeerpShit\Agentics
.\verify-lenovo-i9-setup.ps1
```

## Start

```powershell
.\start-agentics-lenovo-i9-npu.ps1
```

Options:
- `-OnlyUp` — Start without models
- `-SkipModels` — Skip model pulls
- `-OnlyDown` — Stop only
- `-Healthcheck` — Health check only
- `-Logs` — Show logs

## Endpoints

| Port | Service | URL |
|------|---------|-----|
| 3000 | Open WebUI | http://localhost:3000 |
| 8787 | Dashboard | http://localhost:8787 |
| 8788 | Orchestrator | http://localhost:8788 |
| 11434 | Ollama | http://localhost:11434 |
| 5678 | n8n | http://localhost:5678 |
| 5432 | PostgreSQL | localhost:5432 |

## Models

Automatically pulled on startup:
- `llama3.2:3b` — Main reasoning
- `qwen2.5-coder:7b` — Coding tasks
- `nomic-embed-text` — RAG embeddings

## Health Check

```powershell
Invoke-RestMethod "http://127.0.0.1:3000/api/version"
Invoke-RestMethod "http://127.0.0.1:8788/health"
Invoke-RestMethod "http://127.0.0.1:11434/api/tags"
docker ps -a
```

## Docker Commands

```powershell
# Status
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String lenovo

# Logs
docker logs webui-lenovo -n 20
docker logs ollama-lenovo -n 20
docker logs agentics-orch-lenovo -n 20

# Stats
docker stats --no-stream ollama-lenovo webui-lenovo

# Network
docker network inspect agentics_agentnet

# Stop services
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  down

# Stop + clean volumes
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  down -v
```

## Pull Models Manually

```powershell
docker exec ollama-lenovo ollama pull llama3.2:3b
docker exec ollama-lenovo ollama pull qwen2.5-coder:7b
docker exec ollama-lenovo ollama pull nomic-embed-text
docker exec ollama-lenovo ollama list
```

## Troubleshooting

### WebUI Not Responding
```powershell
docker logs webui-lenovo
docker restart webui-lenovo
```

### Ollama No Models
```powershell
docker exec ollama-lenovo ollama list
docker exec ollama-lenovo ollama pull llama3.2:3b
```

### High CPU Usage
```powershell
# Reduce parallelism
# Edit .env.lenovo: OLLAMA_NUM_PARALLEL=1
# Edit .env.lenovo: OLLAMA_KEEP_ALIVE=5m
docker restart ollama-lenovo
```

### Port Already in Use
```powershell
Get-NetTCPConnection -LocalPort 3000 | Select-Object OwningProcess
# Or edit compose override to use different port
```

### Out of Memory
```powershell
# Docker Desktop → Settings → Resources → Increase Memory
docker stats --no-stream  # Check current usage
```

## Configuration

**Compose files:**
- `docker-compose.yml` — Original (do not edit)
- `docker-compose.lenovo-i9-cpu-npu.override.yml` — Lenovo i9 config (NEW)

**Env file:**
- `.env.lenovo` — Credentials & settings template

**Environment (CPU-only):**
```
OLLAMA_NUM_PARALLEL=1
OLLAMA_NUM_THREAD=0
OLLAMA_KEEP_ALIVE=10m
OLLAMA_KV_CACHE_TYPE=q8_0
CUDA_VISIBLE_DEVICES=-1
NVIDIA_VISIBLE_DEVICES=void
```

## Files Reference

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Original RTX stack (do not edit) |
| `docker-compose.lenovo-i9-cpu-npu.override.yml` | CPU-only Lenovo config |
| `start-agentics-lenovo-i9-npu.ps1` | Start/stop/health script |
| `verify-lenovo-i9-setup.ps1` | Pre-flight checks |
| `.env.lenovo` | Environment variables template |
| `README_LENOVO_I9.md` | Full documentation |
| `LENOVO_I9_NPU_STRATEGY.md` | NPU roadmap (6 phases) |

## NPU (Phase 2+)

See `LENOVO_I9_NPU_STRATEGY.md` for:
- Phase 2: NPU verification
- Phase 3: OpenVINO install
- Phase 4: Model conversion
- Phase 5: Docker sidecar
- Phase 5b/5c: WebUI/Orchestrator integration

**Do NOT start Phase 2 until Phase 1 is stable.**

## Rules (Never Violate)

1. ✓ No NVIDIA, CUDA, runtime: nvidia
2. ✓ Use `agentics_agentnet` network
3. ✓ Keep WebUI on port 3000
4. ✓ Keep Orchestrator on port 8788 (maps 3001)
5. ✓ Keep WAHA on port 3001
6. ✓ Use CPU-friendly models (3B, 7B max)
7. ✓ Defer NPU to Phase 2+
8. ✓ Do not destructively edit RTX compose
9. ✓ Always use override file: `-f docker-compose.lenovo-i9-cpu-npu.override.yml`
10. ✓ Use PowerShell on Windows

## One-Liner Start

```powershell
cd C:\DeerpShit\Agentics; .\start-agentics-lenovo-i9-npu.ps1
```

## Emergency Stop

```powershell
docker stop $(docker ps -q)
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  down -v
```
