# Docker Memory Management Guide

## Overview

This setup provides intelligent memory management for your Docker containers with:
- Memory limits per container (prevents runaway consumption)
- Automated daily cleanup (removes orphaned resources)
- Easy pause/resume for high-memory services
- Monitoring tools

## Memory Limits (Updated in docker-compose.yml)

| Service | Limit | Reservation |
|---------|-------|-------------|
| Ollama | 12GB | 6GB |
| Open-WebUI | 1.5GB | 768MB |

**Total safe footprint:** ~13.5GB reserved, 15.5GB max

## Quick Commands

### Check Memory Usage
```bash
# Linux/macOS
./docker-memory-manager.sh status

# Windows
.\docker-memory-manager.ps1 -Action status

# Or use Docker directly
docker stats
```

### Free Up Memory Now
```bash
# Linux/macOS
./docker-memory-manager.sh cleanup

# Windows
.\docker-memory-manager.ps1 -Action cleanup
```

### Pause High-Memory Services
```bash
# Linux/macOS
./docker-memory-manager.sh pause

# Windows
.\docker-memory-manager.ps1 -Action pause
```

### Resume Services
```bash
# Linux/macOS
./docker-memory-manager.sh resume

# Windows
.\docker-memory-manager.ps1 -Action resume
```

## Automated Cleanup Setup

### Linux/macOS
```bash
chmod +x setup-memory-cron.sh
./setup-memory-cron.sh
```

This schedules daily cleanup at 2 AM via cron.

### Windows (Requires Admin)
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
.\setup-memory-scheduler.ps1
```

This creates a Windows Task Scheduler job for daily cleanup at 2 AM.

## How It Works

1. **Memory Limits:** Docker enforces hard limits (`deploy.resources.limits`). Containers won't exceed these.

2. **Reservations:** Docker reserves this memory. Other containers wait if not available.

3. **Cleanup:** Removes stopped containers, dangling images, and volumes older than 24 hours.

4. **Logging:** All actions are logged to `docker-memory-cleanup.log`.

## Reduce Memory Further

If you still need more memory, try:

1. **Use smaller Ollama models:**
   ```bash
   ollama pull mistral:7b  # Smaller than default
   ollama pull neural-chat  # Lightweight
   ```

2. **Disable GPU (if not needed):**
   ```yaml
   environment:
     - OLLAMA_NUM_GPU=0
   ```

3. **Reduce Ollama limit further:**
   ```yaml
   limits:
     memory: 8G
   ```

4. **Stop Ollama when not in use:**
   ```bash
   docker-compose stop ollama
   ```

## Monitor Real-Time

```bash
# Watch memory usage update every 2 seconds
docker stats --no-stream --interval 2
```

## Troubleshooting

**Q: Containers killed unexpectedly**
- Check `docker logs <container>` for OOM messages
- Increase memory limit or reduce model size

**Q: Cleanup isn't running**
- Linux/macOS: `crontab -l` to verify
- Windows: Check Task Scheduler → Task Scheduler Library

**Q: Still running out of memory**
- Pause unused containers: `docker-compose stop <service>`
- Use WSL2 with more allocated RAM (Windows)
- Consider upgrading system RAM
