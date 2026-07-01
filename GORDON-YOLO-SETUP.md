# Gordon YOLO Mode Setup

**Gordon** is Docker's AI agent that can run in **YOLO mode** — executing tasks autonomously without asking permission at each step, all within safe Docker Sandboxes.

## What is YOLO Mode?

YOLO mode lets Gordon:
- Execute commands without confirmation prompts
- Modify files and containers autonomously
- Apply fixes and optimizations automatically
- Move fast while staying safe in isolated Docker Sandboxes

## Quick Start

### 1. Initialize Gordon Sandbox

```bash
bash gordon-yolo.sh init
```

This starts a sandboxed container where Gordon can operate safely.

### 2. Submit a Task

```bash
# Optimize a Dockerfile
bash gordon-yolo.sh optimize ./Dockerfile

# Debug a failing container
bash gordon-yolo.sh debug ollama-service

# Scale a service
bash gordon-yolo.sh scale open-webui 3
```

### 3. Monitor Execution

```bash
# Watch Gordon work
bash gordon-yolo.sh monitor

# Check status
bash gordon-yolo.sh status

# View logs
bash gordon-yolo.sh logs
```

## Available Tasks

### Optimize Dockerfile
```bash
bash gordon-yolo.sh optimize <dockerfile_path>
```

Gordon will:
- Analyze for best practices
- Add multi-stage builds if missing
- Optimize layer caching
- Remove unused dependencies
- Apply security improvements
- Build and verify

### Debug Container
```bash
bash gordon-yolo.sh debug <container_name>
```

Gordon will:
- Check container status
- Review logs
- Inspect configuration
- Run diagnostics
- Suggest and apply fixes
- Test the container

### Scale Service
```bash
bash gordon-yolo.sh scale <service_name> <replicas>
```

Gordon will:
- Update docker-compose.yml
- Scale the service
- Verify health checks
- Load balance if applicable

## Configuration

Edit `gordon-config.yaml` to customize:
- Agent models (OpenAI, Anthropic, local LLM)
- Specialized sub-agents (optimizer, debugger)
- Tool access and permissions
- Memory and reasoning capabilities

## How YOLO Mode is Safe

1. **Docker Sandboxes**: Agents run in isolated microVM containers
2. **Workspace isolation**: Only access `/workspace` directory
3. **Pre-defined scope**: Tasks specify exact objectives
4. **Verified execution**: Results are logged and testable
5. **No system access**: Sandbox can't affect host directly

## Architecture

```
┌──────────────────────────────────┐
│    Host Machine (your PC)        │
│  - docker-compose.yml            │
│  - gordon-yolo.sh (task submitter)│
└────────────┬─────────────────────┘
             │
┌────────────▼─────────────────────┐
│   Docker Sandbox (isolated)       │
│  - Gordon agent runtime           │
│  - Task execution                 │
│  - File workspace                 │
│  - Logs & memory                  │
└──────────────────────────────────┘
```

## Example: Optimize Dockerfile in YOLO Mode

```bash
# Submit task
$ bash gordon-yolo.sh optimize ./Dockerfile

# Output:
# Task submitted: optimize-1704067200
# Gordon will execute autonomously...

# Monitor
$ bash gordon-yolo.sh monitor

# Logs show:
# [00:00] Reading Dockerfile
# [00:01] Analyzing current state
# [00:02] Adding multi-stage build
# [00:03] Optimizing layer caching
# [00:05] Building new image
# [00:12] Verifying size reduction: 850MB → 420MB
# [00:13] Task complete ✓
```

## Logs & History

All Gordon actions are logged to `./gordon_logs/`:
- `action.log` - All executed commands
- `gordon_memory.db` - Context and decisions
- `debug_memory.db` - Troubleshooting records

## Cleanup

```bash
bash gordon-yolo.sh cleanup
```

Removes sandbox and all working files.

## Integration with Compose Watch

You can combine YOLO mode with `docker-compose watch`:

```bash
# Terminal 1: Watch for file changes
docker-compose up --watch

# Terminal 2: Submit optimization tasks
bash gordon-yolo.sh optimize ./Dockerfile
```

## Tips

- Keep tasks focused and specific
- Check logs to verify Gordon's decisions
- Combine with `docker stats` for monitoring
- Use `memory-management.sh` to free RAM before heavy tasks
- Logs help you understand agent reasoning

---

**Sources:**
- https://docs.docker.com/ai/docker-agent/
- https://docs.docker.com/ai/gordon/
- https://github.com/docker/docker-agent
