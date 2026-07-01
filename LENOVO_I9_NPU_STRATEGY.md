# Lenovo i9 NPU Integration Strategy

## Overview

The Lenovo i9 CPU-first Agentics stack is designed for **stability first, NPU later**. This document outlines the strategy for adding Intel NPU acceleration as an optional Phase 2+ sidecar, without blocking the core Docker stack.

## Phase 1: CPU-First Docker Stack (CURRENT)

**Goal:** Stable, proven Agentics/Open WebUI stack on CPU only.

**Services:**
- Open WebUI on port 3000
- Agentics Orchestrator on port 8788
- Agent Dashboard on port 8787
- Ollama on port 11434 (CPU inference)
- N8N on port 5678
- Supporting services (Postgres, Chroma, MinIO, etc.)

**Models:**
- `llama3.2:3b` — main reasoning (CPU-friendly)
- `qwen2.5-coder:7b` — coding tasks (pulled only on demand)
- `nomic-embed-text` — RAG embeddings

**Environment:**
- `OLLAMA_NUM_PARALLEL=1` (no CPU thrashing)
- `OLLAMA_NUM_THREAD=0` (auto-detect)
- `OLLAMA_KEEP_ALIVE=10m`
- `OLLAMA_KV_CACHE_TYPE=q8_0`
- `CUDA_VISIBLE_DEVICES=-1` (no NVIDIA)
- `NVIDIA_VISIBLE_DEVICES=void` (no NVIDIA)

**Testing:**
```powershell
Invoke-RestMethod "http://127.0.0.1:3000/api/version"
Invoke-RestMethod "http://127.0.0.1:8788/health"
Invoke-RestMethod "http://127.0.0.1:11434/api/tags"
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## Phase 2: Intel NPU Verification

**Goal:** Confirm Intel NPU hardware is present and recognized by Windows.

### Step 2.1: Check Device Manager

On Windows, open **Device Manager** and look for:
- **Neural Processing Units** category (or under **Processors**)
- Intel NPU device (e.g., "Intel(R) AI Boost NPU")

If missing:
- Update Intel chipset drivers from Lenovo's support page
- Reboot if drivers were installed

### Step 2.2: Verify Windows System Information

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, SystemFamily
Get-CimInstance Win32_Processor | Select-Object Name, Cores, LogicalProcessors
```

Expected output for i9 with NPU:
```
Manufacturer: Lenovo
Model: <YourModel>

Name: Intel(R) Core(TM) i9-14900K ...
Cores: 24
LogicalProcessors: 32
```

### Step 2.3: Check NPU Driver Status

```powershell
Get-PnpDevice | Where-Object { $_.Name -like "*NPU*" -or $_.Name -like "*Neural*" }
```

If status is "OK", NPU is ready for Phase 3.

---

## Phase 3: OpenVINO Host Installation

**Goal:** Install OpenVINO GenAI tools on the Windows host for model conversion and runtime.

### Step 3.1: Download OpenVINO

- Visit https://www.intel.com/content/www/us/en/developer/tools/openvino-toolkit/overview.html
- Download OpenVINO 2025 or latest for Windows
- Choose **full toolkit** (includes GenAI, NPU plugin, tools)

### Step 3.2: Install OpenVINO

```powershell
# Extract downloaded OpenVINO
$OpenvanoZip = "C:\Downloads\openvino_windows_2025.x.x.zip"
$OpenvanoDir = "C:\intel\openvino"

if (-not (Test-Path $OpenvanoDir)) {
    Expand-Archive -Path $OpenvanoZip -DestinationPath "C:\intel"
}

# Set environment variable
[Environment]::SetEnvironmentVariable("OPENVINO_HOME", $OpenvanoDir, "Machine")
$env:OPENVINO_HOME = $OpenvanoDir
```

### Step 3.3: Verify OpenVINO

```powershell
# List available devices (should include NPU)
cd "$env:OPENVINO_HOME\tools\compiled_models"
python -c "from openvino.runtime import Core; ov = Core(); print('Devices:', ov.available_devices)"

# Expected output:
# Devices: ['CPU', 'GPU', 'NPU']
```

If NPU is missing:
- Reinstall Intel NPU driver (Device Manager → Update driver)
- Reinstall OpenVINO
- Reboot Windows

### Step 3.4: Install OpenVINO GenAI

```powershell
# Install GenAI package (for LLM support on NPU)
pip install openvino-genai --upgrade

# Verify GenAI
python -c "import openvino_genai; print(openvino_genai.__version__)"
```

---

## Phase 4: Model Conversion & NPU Test (Optional/Local)

**Goal:** Convert a small model to OpenVINO IR format and test NPU inference.

### Step 4.1: Download a Small Model

```powershell
# For testing, use a quantized small model (e.g., TinyLlama 1.1B)
mkdir -p C:\models\tinyllama
cd C:\models\tinyllama

# Download from Hugging Face (or use OpenVINO's pre-converted models)
# Example: TinyLlama-1.1B-Chat-v1.0

# For simplicity, use OpenVINO's public model repository
# https://github.com/openvinotoolkit/open_model_zoo

# Or use optimum-intel to auto-convert:
pip install optimum[onnxruntime] optimum-intel
```

### Step 4.2: Convert Model to OpenVINO IR

```powershell
# Use optimum-intel to convert Hugging Face model
python -c "
from optimum.intel.openvino import OVModelForCausalLM
from transformers import AutoTokenizer

model_name = 'TinyLlama/TinyLlama-1.1B-Chat-v1.0'

# Convert and save
ov_model = OVModelForCausalLM.from_pretrained(model_name)
ov_model.save_pretrained('C:/models/tinyllama_ov')

tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.save_pretrained('C:/models/tinyllama_ov')
"
```

### Step 4.3: Test NPU Inference (Local, Non-Docker)

```powershell
# Quick test to verify OpenVINO on NPU works
python -c "
from openvino_genai import LLMPipeline

# Try NPU (will fall back to CPU if NPU unavailable)
pipeline = LLMPipeline('C:/models/tinyllama_ov', device='NPU')
result = pipeline.generate('Hello, how are you?', max_new_tokens=100)
print(result)
"
```

If this works → NPU is functional.  
If fallback to CPU → NPU driver or plugin issue (recheck Phase 2–3).

---

## Phase 5: Docker OpenVINO Sidecar Service

**Goal:** Create a separate Docker service that provides OpenVINO inference via HTTP, then connect Open WebUI/Orchestrator to it.

### Step 5.1: Create Dockerfile for OpenVINO Service

```dockerfile
# Dockerfile.openvino-sidecar
FROM python:3.11-slim-bookworm

WORKDIR /app

# Install OpenVINO and dependencies
RUN pip install --no-cache-dir \
    openvino \
    openvino-genai \
    fastapi \
    uvicorn[standard] \
    pydantic

# Copy model (or mount at runtime)
# COPY models/ /app/models/

# Copy API server code
COPY openvino_api_server.py .

EXPOSE 8000

CMD ["uvicorn", "openvino_api_server:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Step 5.2: Create OpenVINO API Server

```python
# openvino_api_server.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openvino_genai import LLMPipeline
import asyncio
from typing import Optional

app = FastAPI(title="OpenVINO NPU Service")

# Lazy load pipeline (NPU device, falls back to CPU)
pipeline: Optional[LLMPipeline] = None

@app.on_event("startup")
async def startup():
    global pipeline
    try:
        # Try NPU first; will use CPU if NPU unavailable
        pipeline = LLMPipeline("/app/models/tinyllama_ov", device="NPU")
        print("✓ OpenVINO pipeline loaded on NPU")
    except Exception as e:
        print(f"⚠ NPU unavailable, using CPU: {e}")
        pipeline = LLMPipeline("/app/models/tinyllama_ov", device="CPU")

class GenerateRequest(BaseModel):
    prompt: str
    max_tokens: int = 100
    temperature: float = 0.7

@app.post("/generate")
async def generate(req: GenerateRequest):
    """Generate text using OpenVINO model on NPU/CPU."""
    if not pipeline:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        result = pipeline.generate(
            req.prompt,
            max_new_tokens=req.max_tokens,
            top_p=0.9,
            temperature=req.temperature
        )
        return {"response": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    """Health check."""
    return {
        "status": "ok",
        "device": "NPU" if pipeline else "CPU",
    }

@app.get("/models")
async def models():
    """List available models."""
    return {"models": ["tinyllama_ov"]}
```

### Step 5.3: Add OpenVINO Service to Compose

```yaml
# docker-compose.openvino-sidecar.override.yml
services:
  openvino-npu:
    image: openvino-npu-service:latest
    container_name: openvino-npu-lenovo
    restart: unless-stopped
    init: true
    ports:
      - "8765:8000"
    environment:
      DEVICE: "NPU"
    volumes:
      - ./models:/app/models:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - agentics_agentnet
    cpus: "2.0"
    mem_limit: 4g
    mem_reservation: 2g
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

networks:
  agentics_agentnet:
    name: agentics_agentnet
    driver: bridge
```

### Step 5.4: Start Docker OpenVINO Service

```powershell
# Build sidecar image
docker build -f Dockerfile.openvino-sidecar -t openvino-npu-service .

# Start with override
docker compose \
  -f docker-compose.yml \
  -f docker-compose.lenovo-i9-cpu-npu.override.yml \
  -f docker-compose.openvino-sidecar.override.yml \
  up -d openvino-npu

# Test
Invoke-RestMethod "http://127.0.0.1:8765/health"
```

---

## Phase 5b: Connect Open WebUI to OpenVINO Backend (Optional)

Once OpenVINO sidecar is running, you can optionally add it as a secondary backend to Open WebUI:

### Option A: Via Open WebUI Settings (UI)

1. Go to http://localhost:3000/admin/settings
2. Add **Custom OpenAI-compatible endpoint:**
   - Name: `OpenVINO NPU`
   - URL: `http://openvino-npu:8000`
   - Model: `tinyllama_ov`

### Option B: Via Environment Variable

```yaml
# In docker-compose.lenovo-i9-cpu-npu.override.yml
open-webui:
  environment:
    OPENAI_API_KEY: ""
    OPENAI_API_BASE: "http://openvino-npu:8000/v1"
```

---

## Phase 5c: Connect Agentics Orchestrator to OpenVINO Backend (Optional)

Update the orchestrator config to use OpenVINO for faster coding tasks:

```yaml
# In docker-compose.lenovo-i9-cpu-npu.override.yml
agentics-orchestrator:
  environment:
    # Primary orchestrator model (stays on Ollama CPU)
    ORCHESTRATOR_MODEL: "llama3.2:3b"
    
    # Optional: NPU coding model (if OpenVINO available)
    CODING_MODEL_NPU_ENABLED: "true"
    CODING_MODEL_NPU_URL: "http://openvino-npu:8000"
    CODING_MODEL_NPU_NAME: "tinyllama_ov"
```

---

## Phase 6: Monitoring & Optimization

### Monitor NPU Usage

```powershell
# Watch Docker container stats
docker stats --no-stream openvino-npu-lenovo

# Check OpenVINO device usage
curl -s http://127.0.0.1:8765/health | ConvertFrom-Json | Select-Object device
```

### Optimize Model for NPU

If inference is slow, consider:
1. **Quantization:** Use INT8 or lower precision
2. **Model size:** Start with 1B–3B models; scale up if performance is acceptable
3. **Batch size:** Set batch size based on available VRAM

---

## Troubleshooting

### OpenVINO Not Detecting NPU

**Symptom:** `Available devices: ['CPU']`

**Solutions:**
1. Verify NPU in Device Manager (Phase 2.1)
2. Update Intel chipset drivers (Phase 2.1)
3. Reinstall OpenVINO (Phase 3.2)
4. Check if OpenVINO build includes NPU plugin: `python -c "from openvino.runtime import Core; print(Core().available_devices)"`
5. Reboot Windows

### Docker Container Can't Access Host NPU

**Symptom:** OpenVINO sidecar falls back to CPU

**Explanation:** Docker containers on Windows (via WSL2/Hyper-V) cannot directly access host NPU. The container itself runs on CPU. This is expected; the sidecar will infer on CPU inside the container.

**Solution:** Treat NPU as a host-side service only (Phase 4), not Docker-containerized.

### Model Conversion Fails

**Symptom:** `Error: UnsupportedModel` or `Device='NPU' not found`

**Solutions:**
1. Ensure OpenVINO is installed correctly: `pip list | grep openvino`
2. Try a different model (e.g., smaller 1B instead of 7B)
3. Use pre-converted models from OpenVINO Model Zoo
4. Check OpenVINO version compatibility with model format

### Slow NPU Inference

**Symptom:** NPU inference is slower than expected

**Solutions:**
1. Verify NPU is actually being used: add logging to API server
2. Check for CPU fallback (check logs)
3. Reduce model size (start with TinyLlama, scale up)
4. Profile with Intel VTune Profiler (advanced)

---

## Checkpoint: When to Move to Phase 5+

Move to Phase 5 **only when**:
- ✓ Phase 1 (CPU stack) is stable and tested
- ✓ Phase 2 (NPU hardware) is confirmed present
- ✓ Phase 3 (OpenVINO) is installed and working
- ✓ Phase 4 (model conversion) succeeded locally
- ✓ You have a specific use case (e.g., "faster coding model inference")

**Do not** try to skip to Phase 5 without Phase 1–4 completed.

---

## Summary: Lenovo i9 NPU Roadmap

| Phase | Goal | Status | Timeline |
|-------|------|--------|----------|
| 1     | CPU-first Docker stack | **ACTIVE** | Now |
| 2     | NPU hardware verification | When ready | Week 2 |
| 3     | OpenVINO host install | When ready | Week 3 |
| 4     | Model conversion & test | Optional | Week 4 |
| 5     | Docker OpenVINO sidecar | When needed | Week 5+ |
| 5b    | WebUI NPU backend | When needed | Week 6+ |
| 5c    | Orchestrator NPU coding | When needed | Week 7+ |

**Current recommendation:** Complete Phase 1, then assess Phase 2–3 if additional performance is needed.
