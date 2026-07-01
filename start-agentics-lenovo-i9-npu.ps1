# ============================================================================
# START AGENTICS LENOVO I9 CPU-FIRST STACK
# ============================================================================
# PowerShell script to start the Lenovo i9 Agentics stack
# - CPU-only Ollama with llama3.2:3b, qwen2.5-coder:7b, nomic-embed-text
# - No NVIDIA, no CUDA, no runtime: nvidia
# - Intel NPU deferred to Phase 2+ (OpenVINO sidecar bridge)
# - Network: agentics_agentnet
# - Ports: 3000 (WebUI), 8787 (Dashboard), 8788 (Orchestrator), 11434 (Ollama)
#
# Usage:
#   .\start-agentics-lenovo-i9-npu.ps1
#
# ============================================================================

param(
    [switch]$SkipPull = $false,
    [switch]$SkipModels = $false,
    [switch]$OnlyUp = $false,
    [switch]$OnlyDown = $false,
    [switch]$Healthcheck = $false,
    [switch]$Logs = $false
)

# Colors for output
$Colors = @{
    Green   = @{ FG = 'Green'; }
    Red     = @{ FG = 'Red'; }
    Yellow  = @{ FG = 'Yellow'; }
    Blue    = @{ FG = 'Blue'; }
    Cyan    = @{ FG = 'Cyan'; }
}

function Log-Info { Write-Host @Colors.Cyan "ℹ️  $args" }
function Log-Success { Write-Host @Colors.Green "✓ $args" }
function Log-Warn { Write-Host @Colors.Yellow "⚠️  $args" }
function Log-Error { Write-Host @Colors.Red "✗ $args" }
function Log-Section { Write-Host "`n" ; Write-Host @Colors.Blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" ; Write-Host @Colors.Blue "  $args" ; Write-Host @Colors.Blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" }

# Defaults
$ProjectRoot = $PSScriptRoot
$ComposeFiles = @(
    "docker-compose.yml",
    "docker-compose.lenovo-i9-cpu-npu.override.yml"
)

$Services = @(
    "postgres-lenovo",
    "ollama-lenovo",
    "webui-lenovo",
    "agent-dashboard-lenovo",
    "agentics-orch-lenovo"
)

$RequiredModels = @(
    "llama3.2:3b",
    "qwen2.5-coder:7b",
    "nomic-embed-text"
)

$HealthEndpoints = @{
    "WebUI"        = "http://127.0.0.1:3000/api/version"
    "Dashboard"    = "http://127.0.0.1:8787"
    "Orchestrator" = "http://127.0.0.1:8788/health"
    "Ollama"       = "http://127.0.0.1:11434/api/tags"
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Invoke-DockerCompose {
    param([string]$Command)
    $Compose = $ComposeFiles | ForEach-Object { "-f `"$ProjectRoot/$_`"" } | Join-String -Separator " "
    $Cmd = "docker compose $Compose $Command"
    Log-Info "Running: $Cmd"
    Invoke-Expression $Cmd
}

function Test-HealthEndpoint {
    param([string]$Name, [string]$Url)
    try {
        $Response = Invoke-RestMethod $Url -TimeoutSec 5 -ErrorAction Stop
        Log-Success "$Name is healthy"
        return $true
    }
    catch {
        Log-Warn "$Name check failed: $($_.Exception.Message)"
        return $false
    }
}

function Pull-OllamaModels {
    Log-Section "PULLING OLLAMA MODELS"
    
    foreach ($Model in $RequiredModels) {
        Log-Info "Pulling model: $Model"
        docker exec ollama-lenovo ollama pull $Model
        if ($LASTEXITCODE -eq 0) {
            Log-Success "Model pulled: $Model"
        }
        else {
            Log-Error "Failed to pull $Model"
        }
    }
    
    Log-Info "`nVerifying models..."
    docker exec ollama-lenovo ollama list
}

function Start-Stack {
    Log-Section "STARTING AGENTICS LENOVO I9 STACK"
    
    Log-Info "Docker Compose files: $($ComposeFiles -join ', ')"
    Log-Info "Project root: $ProjectRoot"
    Log-Info "Network: agentics_agentnet"
    
    # Change to project root
    Push-Location $ProjectRoot
    
    try {
        # Stop existing stack
        Log-Info "Stopping existing containers..."
        Invoke-DockerCompose "down -v --remove-orphans" 2>&1 | Write-Host
        
        # Start core services (postgres, ollama, webui)
        Log-Info "Starting core services..."
        Invoke-DockerCompose "up -d postgres-lenovo ollama-lenovo webui-lenovo" 2>&1 | Write-Host
        
        Log-Success "Core services started"
        
        # Wait for Ollama to be ready
        Log-Info "Waiting for Ollama to be healthy (30s)..."
        Start-Sleep -Seconds 30
        
        # Pull models if not skipped
        if (-not $SkipModels) {
            Pull-OllamaModels
            Start-Sleep -Seconds 10
        }
        
        # Start orchestrator and dashboard
        Log-Info "Starting orchestrator and dashboard..."
        Invoke-DockerCompose "up -d agent-dashboard-lenovo agentics-orch-lenovo" 2>&1 | Write-Host
        
        Log-Success "Agentics stack started"
    }
    finally {
        Pop-Location
    }
}

function Stop-Stack {
    Log-Section "STOPPING AGENTICS LENOVO I9 STACK"
    
    Push-Location $ProjectRoot
    try {
        Invoke-DockerCompose "down -v" 2>&1 | Write-Host
        Log-Success "Stack stopped"
    }
    finally {
        Pop-Location
    }
}

function Show-Status {
    Log-Section "CONTAINER STATUS"
    
    $Format = "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
    docker ps -a --format $Format | Select-String -Pattern "lenovo"
    
    Log-Section "NETWORK STATUS"
    docker network inspect agentics_agentnet --format "table {{.Containers | json}}" 2>&1 | Select-Object -First 5
}

function Test-Health {
    Log-Section "HEALTH CHECKS"
    
    $HealthEndpoints.GetEnumerator() | ForEach-Object {
        Test-HealthEndpoint $_.Name $_.Value
        Start-Sleep -Milliseconds 500
    }
    
    Log-Section "OLLAMA MODELS"
    try {
        $Response = Invoke-RestMethod "http://127.0.0.1:11434/api/tags" -TimeoutSec 5
        if ($Response.models) {
            Log-Success "Ollama has $($Response.models.Count) models:"
            $Response.models | ForEach-Object { Log-Info "  - $($_.name)" }
        }
        else {
            Log-Warn "No models found in Ollama"
        }
    }
    catch {
        Log-Error "Could not query Ollama: $($_.Exception.Message)"
    }
}

function Show-Logs {
    Log-Section "CONTAINER LOGS"
    
    Push-Location $ProjectRoot
    try {
        Invoke-DockerCompose "logs -n 50 --timestamps"
    }
    finally {
        Pop-Location
    }
}

function Show-Help {
    @"
╔══════════════════════════════════════════════════════════════════════════════╗
║          START AGENTICS LENOVO I9 CPU-FIRST STACK                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

USAGE:
  .\start-agentics-lenovo-i9-npu.ps1 [OPTIONS]

OPTIONS:
  (default)              Start full stack with model pulls
  -OnlyUp                Only start services (no model pull)
  -OnlyDown              Only stop services
  -SkipModels            Skip Ollama model pulls
  -SkipPull              Skip Docker image pulls
  -Healthcheck           Run health checks only (no start/stop)
  -Logs                  Show recent container logs
  -?                     Show this help

EXAMPLES:
  # Start stack (pulls models)
  .\start-agentics-lenovo-i9-npu.ps1

  # Start only containers (assume models exist)
  .\start-agentics-lenovo-i9-npu.ps1 -SkipModels

  # Stop stack
  .\start-agentics-lenovo-i9-npu.ps1 -OnlyDown

  # Health check
  .\start-agentics-lenovo-i9-npu.ps1 -Healthcheck

SERVICES:
  Port 3000  = Open WebUI (http://localhost:3000)
  Port 8787  = Agent Dashboard (http://localhost:8787)
  Port 8788  = Agentics Orchestrator (http://localhost:8788)
  Port 11434 = Ollama API (http://localhost:11434)
  Port 5678  = n8n (http://localhost:5678)
  Port 5432  = PostgreSQL

MODELS (auto-pulled if not skipped):
  - llama3.2:3b (main reasoning model)
  - qwen2.5-coder:7b (coding tasks)
  - nomic-embed-text (RAG embeddings)

NETWORK:
  agentics_agentnet (172.24.0.0/16)

CPU OPTIMIZATION:
  - OLLAMA_NUM_PARALLEL=1 (no CPU thrashing)
  - OLLAMA_NUM_THREAD=0 (auto-detect)
  - OLLAMA_KEEP_ALIVE=10m
  - OLLAMA_KV_CACHE_TYPE=q8_0
  - CUDA_VISIBLE_DEVICES=-1 (no NVIDIA)

NPU STRATEGY (Phase 2+):
  Phase 1: CPU-first Docker stack (THIS)
  Phase 2: Verify Intel NPU in Device Manager
  Phase 3: Install/test OpenVINO on Windows host
  Phase 4: Create OpenVINO sidecar service
  Phase 5: Connect WebUI/Orchestrator to OpenVINO backend

"@
}

# ============================================================================
# MAIN
# ============================================================================

Log-Section "AGENTICS LENOVO I9 CPU-FIRST STACK LAUNCHER"

if ($OnlyDown) {
    Stop-Stack
    exit 0
}

if ($OnlyUp) {
    Start-Stack
    Show-Status
    exit 0
}

if ($Healthcheck) {
    Show-Status
    Test-Health
    exit 0
}

if ($Logs) {
    Show-Logs
    exit 0
}

if ($PSBoundParameters.Help -or $PSBoundParameters.ContainsKey('?')) {
    Show-Help
    exit 0
}

# Default: full start
Start-Stack
Show-Status
Test-Health

Log-Section "STARTUP COMPLETE"
Log-Success "Agentics Lenovo i9 CPU-first stack is running!"
Log-Info "Open WebUI: http://localhost:3000"
Log-Info "Dashboard:  http://localhost:8787"
Log-Info "Orchestrator: http://localhost:8788"
Log-Info "Ollama:     http://localhost:11434"

Write-Host "`n"
