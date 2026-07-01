import os
import subprocess
from pathlib import Path

import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

WORKSPACE_DIR = Path(os.getenv("WORKSPACE_DIR", "/workspace")).resolve()
WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")
PLAYWRIGHT_MCP_URL = os.getenv("PLAYWRIGHT_MCP_URL", "http://playwright-mcp:3010")
N8N_URL = os.getenv("N8N_URL", "http://n8n:5678")
MAX_COMMAND_TIMEOUT = int(os.getenv("MAX_COMMAND_TIMEOUT", "30"))

app = FastAPI(title="Agentics Tools API", version="1.0.0")


class ShellRequest(BaseModel):
    command: str
    timeout: int = 30


class FileWriteRequest(BaseModel):
    path: str
    content: str


class OllamaGenerateRequest(BaseModel):
    model: str = "llama3.1"
    prompt: str
    stream: bool = False


def safe_path(path: str) -> Path:
    target = (WORKSPACE_DIR / path).resolve()
    if not str(target).startswith(str(WORKSPACE_DIR)):
        raise HTTPException(status_code=400, detail="Path escapes workspace")
    return target


@app.get("/")
def root():
    return {"name": "Agentics Tools API", "status": "ok", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/services")
def services():
    return {
        "ollama": OLLAMA_BASE_URL,
        "playwright_mcp": PLAYWRIGHT_MCP_URL,
        "n8n": N8N_URL,
        "workspace": str(WORKSPACE_DIR),
    }


@app.get("/ollama/tags")
def ollama_tags():
    try:
        r = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=10)
        r.raise_for_status()
        return r.json()
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Ollama unavailable: {exc}")


@app.post("/ollama/generate")
def ollama_generate(req: OllamaGenerateRequest):
    try:
        r = requests.post(f"{OLLAMA_BASE_URL}/api/generate", json=req.model_dump(), timeout=120)
        r.raise_for_status()
        return r.json()
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Ollama generate failed: {exc}")


@app.get("/files/list")
def list_files(path: str = "."):
    folder = safe_path(path)
    if not folder.exists():
        raise HTTPException(status_code=404, detail="Path not found")
    if not folder.is_dir():
        raise HTTPException(status_code=400, detail="Path is not a directory")
    return {
        "path": str(folder.relative_to(WORKSPACE_DIR)),
        "items": [
            {
                "name": p.name,
                "type": "dir" if p.is_dir() else "file",
                "size": p.stat().st_size if p.is_file() else None,
            }
            for p in sorted(folder.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))
        ],
    }


@app.get("/files/read")
def read_file(path: str):
    target = safe_path(path)
    if not target.exists() or not target.is_file():
        raise HTTPException(status_code=404, detail="File not found")
    return {"path": path, "content": target.read_text(encoding="utf-8", errors="replace")}


@app.post("/files/write")
def write_file(req: FileWriteRequest):
    target = safe_path(req.path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(req.content, encoding="utf-8")
    return {"status": "ok", "path": req.path}


@app.post("/execute")
def execute(req: ShellRequest):
    timeout = min(req.timeout, MAX_COMMAND_TIMEOUT)
    blocked = {"docker", "shutdown", "reboot", "format", "powershell", "pwsh", "mount", "umount", "sudo", "su"}
    first = req.command.strip().split(" ")[0].lower()
    if first in blocked:
        raise HTTPException(status_code=403, detail=f"Command blocked: {first}")

    try:
        result = subprocess.run(
            req.command,
            shell=True,
            cwd=str(WORKSPACE_DIR),
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return {"returncode": result.returncode, "stdout": result.stdout[-20000:], "stderr": result.stderr[-20000:]}
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=408, detail="Command timed out")
