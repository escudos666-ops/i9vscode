# Lenovo i9 Agentics Stack — Deployment Checklist

## Pre-Deployment (Phase 1 Setup)

### Environment Preparation
- [ ] Windows Docker Desktop installed & running
- [ ] Docker Compose V2 available (`docker compose version`)
- [ ] Project root: `C:\DeerpShit\Agentics`
- [ ] Sufficient disk space (>50GB for models + containers)
- [ ] Memory available in Docker Desktop settings (20GB+ recommended)

### File Verification
- [ ] `docker-compose.yml` exists (original, do NOT edit)
- [ ] `docker-compose.lenovo-i9-cpu-npu.override.yml` created (NEW)
- [ ] `start-agentics-lenovo-i9-npu.ps1` created (NEW)
- [ ] `verify-lenovo-i9-setup.ps1` created (NEW)
- [ ] `.env.lenovo` created or template available (NEW)

### Documentation in Place
- [ ] `README_LENOVO_I9.md` present
- [ ] `LENOVO_I9_NPU_STRATEGY.md` present
- [ ] `LENOVO_I9_QUICK_REF.md` present
- [ ] `LENOVO_I9_DELIVERABLES.md` present

### Pre-Flight Checks
- [ ] Run `.\verify-lenovo-i9-setup.ps1` → All checks pass
- [ ] No critical failures reported
- [ ] Warnings reviewed and acceptable

---

## Deployment (Phase 1 Start)

### Initial Startup
- [ ] Navigate to project root: `cd C:\DeerpShit\Agentics`
- [ ] Run start script: `.\start-agentics-lenovo-i9-npu.ps1`
- [ ] Script completes without errors
- [ ] Containers started successfully
- [ ] Model pull begins (llama3.2:3b, qwen2.5-coder:7b, nomic-embed-text)

### Service Health (Check Every 2-3 Minutes)

#### Core Services Coming Up
- [ ] postgres-lenovo: healthy (database initialized)
- [ ] ollama-lenovo: healthy (model pull in progress)
- [ ] webui-lenovo: starting (waiting for Ollama)
- [ ] agent-dashboard-lenovo: pending
- [ ] agentics-orch-lenovo: pending

#### Models Pulling (Monitor for 10-20 minutes)
- [ ] llama3.2:3b pull started
- [ ] qwen2.5-coder:7b pull started
- [ ] nomic-embed-text pull started
- [ ] No errors in `docker logs ollama-lenovo`
- [ ] Pull completion visible in console output

#### Services Stabilizing
- [ ] webui-lenovo: healthy (after Ollama ready)
- [ ] agent-dashboard-lenovo: healthy
- [ ] agentics-orch-lenovo: healthy
- [ ] All health checks visible in console

---

## Post-Deployment Verification (Phase 1)

### Endpoint Tests

#### Open WebUI (Port 3000)
```powershell
Invoke-RestMethod "http://127.0.0.1:3000/api/version"
```
- [ ] Returns HTTP 200
- [ ] Response shows version info
- [ ] WebUI accessible at http://localhost:3000
- [ ] Login/dashboard visible in browser

#### Agent Dashboard (Port 8787)
```powershell
Invoke-RestMethod "http://127.0.0.1:8787"
```
- [ ] Returns HTTP 200 or 302 (redirect acceptable)
- [ ] Dashboard accessible at http://localhost:8787
- [ ] Shows agent status UI

#### Orchestrator (Port 8788)
```powershell
Invoke-RestMethod "http://127.0.0.1:8788/health"
```
- [ ] Returns HTTP 200
- [ ] Response includes `{"status": "ok"}` or similar
- [ ] Orchestrator API responsive

#### Ollama (Port 11434)
```powershell
Invoke-RestMethod "http://127.0.0.1:11434/api/tags"
```
- [ ] Returns HTTP 200
- [ ] Response includes models array
- [ ] Contains at least 3 models:
  - [ ] `llama3.2:3b`
  - [ ] `qwen2.5-coder:7b`
  - [ ] `nomic-embed-text`

#### Container Status
```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
- [ ] All core services show "Up" status
- [ ] No "Exited" or "Dead" containers
- [ ] Ports correctly mapped (3000, 8787, 8788, 11434, 5678, 5432)

### Network Verification

#### agentics_agentnet Check
```powershell
docker network inspect agentics_agentnet
```
- [ ] Network exists
- [ ] Subnet: 172.24.0.0/16
- [ ] All core containers connected:
  - [ ] postgres-lenovo
  - [ ] ollama-lenovo
  - [ ] webui-lenovo
  - [ ] agent-dashboard-lenovo
  - [ ] agentics-orch-lenovo

#### Cross-Container Connectivity
```powershell
docker exec webui-lenovo curl -s http://ollama-lenovo:11434/api/tags
```
- [ ] Returns Ollama models (confirms connectivity)
- [ ] No "Connection refused" errors

### Database Verification

#### PostgreSQL Health
```powershell
docker exec postgres-lenovo psql -U webui -d openwebui -c "SELECT 1;"
```
- [ ] Returns: `1` (query result)
- [ ] Database is accessible

#### Schema Initialization
```powershell
docker exec postgres-lenovo psql -U webui -d openwebui -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname='public';"
```
- [ ] Returns: `> 0` (tables exist)
- [ ] Database schema initialized by WebUI

### Performance Baseline

#### CPU Usage
```powershell
docker stats --no-stream ollama-lenovo webui-lenovo
```
- [ ] Ollama CPU: 5-15% (idle)
- [ ] Ollama CPU: 60-90% (during inference)
- [ ] WebUI CPU: 2-5% (idle)

#### Memory Usage
```powershell
docker stats --no-stream
```
- [ ] Ollama: <16GB (within limit)
- [ ] WebUI: <6GB (within limit)
- [ ] Postgres: <2GB (within limit)
- [ ] Total: <30GB (i9 should have headroom)

#### Disk Space
```powershell
docker system df
```
- [ ] `Containers`: <20GB
- [ ] `Images`: <50GB
- [ ] `Local Volumes`: <20GB (model storage)
- [ ] Total free space: >50GB recommended

---

## Functional Testing (Phase 1)

### WebUI Interaction

#### Login
- [ ] Access http://localhost:3000
- [ ] Default login works or new account created
- [ ] Dashboard visible

#### Model Selection
- [ ] Click model selector
- [ ] Models appear: llama3.2:3b, qwen2.5-coder:7b, others
- [ ] Can select llama3.2:3b

#### Chat Test
- [ ] Type prompt: "Hello, what is your name?"
- [ ] Send message
- [ ] Response generated (CPU inference)
- [ ] Response appears in chat
- [ ] No timeout or error messages

#### RAG Test (if enabled)
- [ ] Upload a document (PDF, TXT)
- [ ] Type query about document content
- [ ] Response references document
- [ ] embedding model (nomic-embed-text) active

### Orchestrator Interaction

#### Orchestrator Health
- [ ] Access http://localhost:8788/health
- [ ] Returns healthy status
- [ ] Service list available

#### Orchestrator Agent Loop (Simple)
- [ ] Call `/api/orchestrate` with simple task
- [ ] Orchestrator receives task
- [ ] Returns structured response
- [ ] No timeout (stream: false verified)

### Dashboard Interaction

#### Dashboard Display
- [ ] Access http://localhost:8787
- [ ] Agent status visible
- [ ] Container metrics visible
- [ ] No errors in logs

---

## Configuration Verification (Phase 1)

### CPU Settings Confirmed
```powershell
docker exec ollama-lenovo sh -c "echo \$OLLAMA_NUM_PARALLEL && echo \$OLLAMA_KEEP_ALIVE"
```
- [ ] OLLAMA_NUM_PARALLEL: 1 (confirmed)
- [ ] OLLAMA_KEEP_ALIVE: 10m (confirmed)

### No NVIDIA References
```powershell
docker exec webui-lenovo sh -c "echo \$CUDA_VISIBLE_DEVICES && echo \$NVIDIA_VISIBLE_DEVICES"
```
- [ ] CUDA_VISIBLE_DEVICES: -1 (confirmed)
- [ ] NVIDIA_VISIBLE_DEVICES: void (confirmed)

### Network Configuration
- [ ] Network: agentics_agentnet (confirmed)
- [ ] Ports: 3000, 8787, 8788, 11434 (confirmed)
- [ ] No 3001 conflict (WAHA reserved, tools on 8765)

### Environment Variables
- [ ] .env.lenovo template exists
- [ ] Credentials section filled (or defaults acceptable)
- [ ] Secrets not committed to git (check .gitignore)

---

## Stability Testing (Phase 1)

### Sustained Load (15-30 minutes)

#### Repeated Queries
```powershell
# Run in loop in WebUI
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Query $i..."
    # Send chat message in WebUI
    Start-Sleep -Seconds 10
}
```
- [ ] All queries complete successfully
- [ ] No memory leaks observed (`docker stats`)
- [ ] No container crashes
- [ ] Response times consistent

#### Background Monitoring
```powershell
docker stats --no-stream ollama-lenovo webui-lenovo postgres-lenovo
```
- [ ] No container exited unexpectedly
- [ ] Memory usage stable
- [ ] CPU usage normalized between queries

#### Log Review
```powershell
docker logs --tail 100 ollama-lenovo webui-lenovo agentics-orch-lenovo
```
- [ ] No ERROR or CRITICAL messages
- [ ] Warnings acceptable and non-blocking
- [ ] Inference logged correctly

---

## Disaster Recovery Test (Phase 1)

### Stop & Restart
```powershell
docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  down

docker compose -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  up -d postgres-lenovo ollama-lenovo webui-lenovo
```
- [ ] Containers stop cleanly
- [ ] Containers restart cleanly
- [ ] Data persists (models still loaded)
- [ ] Health checks pass after restart

### Partial Failure Recovery
```powershell
# Restart one service
docker restart webui-lenovo
```
- [ ] Single service restarts
- [ ] Other services unaffected
- [ ] Service rejoin network automatically
- [ ] Connectivity re-established

---

## Documentation Validation

### README Accuracy
- [ ] All port numbers correct (3000, 8788, 11434)
- [ ] All service names correct (lenovo suffix)
- [ ] Network name correct (agentics_agentnet)
- [ ] Commands tested and working

### Quick Reference Card
- [ ] All one-liners tested
- [ ] Commands produce expected output
- [ ] Links/references accurate

### NPU Strategy Document
- [ ] Phase 1–2 explained clearly
- [ ] Phase 2+ roadmap outlined
- [ ] No blocking statements on Phase 1
- [ ] Ready for future reference

---

## Sign-Off (Phase 1 Complete)

### All Checks Passed?
- [ ] Pre-deployment: ✓
- [ ] Deployment: ✓
- [ ] Post-deployment verification: ✓
- [ ] Functional testing: ✓
- [ ] Configuration verification: ✓
- [ ] Stability testing: ✓
- [ ] Disaster recovery: ✓
- [ ] Documentation: ✓

### Phase 1 Status: **READY FOR PRODUCTION**

- ✓ CPU-first stack stable on Lenovo i9
- ✓ All endpoints responding
- ✓ Models loaded and inferencing
- ✓ No NVIDIA/CUDA artifacts
- ✓ Correct network & ports
- ✓ Documentation complete
- ✓ Scripts tested and working

### Next Steps
- [ ] Run stack in production use case
- [ ] Monitor for 1-2 weeks
- [ ] Document any issues
- [ ] When stable, consider Phase 2 (NPU) if performance improvement needed
- [ ] Refer to `LENOVO_I9_NPU_STRATEGY.md` for Phase 2+ guidance

---

## Maintenance Reminders

### Weekly
- [ ] Review container logs for errors
- [ ] Check memory/CPU usage trends
- [ ] Verify all endpoints responsive

### Monthly
- [ ] Update Docker images: `docker pull`
- [ ] Prune unused images/volumes: `docker system prune`
- [ ] Backup database: `docker exec postgres-lenovo pg_dump`

### As Needed
- [ ] Add new integrations (tools, models, services)
- [ ] Scale resources if needed
- [ ] Plan Phase 2 (NPU) if performance improvement desired
- [ ] Review logs for security issues

---

## Emergency Contacts / Resources

- Docker Desktop Issues: https://docs.docker.com/desktop/troubleshoot/
- Ollama Docs: https://ollama.ai/
- Open WebUI Docs: https://docs.openwebui.com/
- Project Issues: See project repository

---

## Final Checklist Summary

**Ready to Deploy:** All items above checked and passing  
**Deployment Date:** __________  
**Deployed By:** __________  
**Verified By:** __________  
**Notes:** ____________________________________________________

---

**Phase 1 (CPU-First) Complete. NPU (Phase 2+) Ready for Future Implementation.**
