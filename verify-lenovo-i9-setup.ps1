# ============================================================================
# LENOVO I9 AGENTICS STACK — PRE-FLIGHT CHECKS
# ============================================================================
# Verify Docker, compose files, network, and ports before starting
#
# Usage:
#   .\verify-lenovo-i9-setup.ps1
#
# ============================================================================

param(
    [switch]$Verbose = $false,
    [switch]$SkipPortCheck = $false,
    [switch]$SkipNetworkCheck = $false
)

$Colors = @{
    Green   = @{ FG = 'Green'; }
    Red     = @{ FG = 'Red'; }
    Yellow  = @{ FG = 'Yellow'; }
    Blue    = @{ FG = 'Blue'; }
    Cyan    = @{ FG = 'Cyan'; }
    Gray    = @{ FG = 'Gray'; }
}

function Log-Info { Write-Host @Colors.Cyan "ℹ️  $args" }
function Log-Success { Write-Host @Colors.Green "✓ $args" }
function Log-Warn { Write-Host @Colors.Yellow "⚠️  $args" }
function Log-Error { Write-Host @Colors.Red "✗ $args" }
function Log-Section { Write-Host "`n" ; Write-Host @Colors.Blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" ; Write-Host @Colors.Blue "  $args" ; Write-Host @Colors.Blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" }
function Log-Verbose { if ($Verbose) { Write-Host @Colors.Gray "  → $args" } }

$ProjectRoot = $PSScriptRoot
$ChecksPassed = 0
$ChecksFailed = 0

# ============================================================================
# CHECK: Docker Installation
# ============================================================================

Log-Section "CHECKING DOCKER INSTALLATION"

try {
    $DockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Docker is installed"
        Log-Verbose $DockerVersion
        $ChecksPassed++
    }
    else {
        throw "Docker command failed"
    }
}
catch {
    Log-Error "Docker not found: $_"
    Log-Info "Install from https://www.docker.com/products/docker-desktop"
    $ChecksFailed++
}

# Docker daemon running?
try {
    $DockerInfo = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Docker daemon is running"
        $ChecksPassed++
    }
    else {
        throw "Docker daemon not responding"
    }
}
catch {
    Log-Error "Docker daemon not accessible: $_"
    Log-Info "Start Docker Desktop and try again"
    $ChecksFailed++
}

# ============================================================================
# CHECK: Docker Compose
# ============================================================================

Log-Section "CHECKING DOCKER COMPOSE"

try {
    $ComposeVersion = docker compose version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Docker Compose is available"
        Log-Verbose $ComposeVersion
        $ChecksPassed++
    }
    else {
        throw "Docker Compose not available"
    }
}
catch {
    Log-Error "Docker Compose not found: $_"
    Log-Info "Install the Docker Compose plugin and try again"
    $ChecksFailed++
}

# ============================================================================
# CHECK: Compose Files
# ============================================================================

Log-Section "CHECKING COMPOSE FILES"

$ComposeFiles = @(
    "docker-compose.yml",
    "docker-compose.lenovo-i9-cpu-npu.override.yml"
)

foreach ($File in $ComposeFiles) {
    $FilePath = Join-Path $ProjectRoot $File
    if (Test-Path $FilePath) {
        $Size = (Get-Item $FilePath).Length
        Log-Success "$File exists ($Size bytes)"
        Log-Verbose $FilePath
        $ChecksPassed++
    }
    else {
        Log-Error "$File not found"
        Log-Info "Create it in: $ProjectRoot"
        $ChecksFailed++
    }
}

# ============================================================================
# CHECK: Start Script
# ============================================================================

Log-Section "CHECKING START SCRIPT"

$StartScript = Join-Path $ProjectRoot "start-agentics-lenovo-i9-npu.ps1"
if (Test-Path $StartScript) {
    Log-Success "Start script exists"
    Log-Verbose $StartScript
    $ChecksPassed++
}
else {
    Log-Error "Start script not found: $StartScript"
    $ChecksFailed++
}

# ============================================================================
# CHECK: .env File
# ============================================================================

Log-Section "CHECKING .ENV FILES"

$EnvFiles = @(
    ".env.lenovo"
)

foreach ($File in $EnvFiles) {
    $FilePath = Join-Path $ProjectRoot $File
    if (Test-Path $FilePath) {
        Log-Success "$File exists"
        Log-Verbose $FilePath
        
        # Warn if passwords are default
        $Content = Get-Content $FilePath
        if ($Content -match "your-secure-postgres-password") {
            Log-Warn "$File contains default password — change this before production!"
        }
        
        $ChecksPassed++
    }
    else {
        Log-Warn "$File not found (copy from template or use defaults)"
        $ChecksFailed++
    }
}

# ============================================================================
# CHECK: Network Configuration
# ============================================================================

if (-not $SkipNetworkCheck) {
    Log-Section "CHECKING NETWORK CONFIGURATION"
    
    # Check if agentics_agentnet exists
    try {
        $Network = docker network inspect agentics_agentnet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Log-Warn "Network agentics_agentnet already exists"
            Log-Verbose "It will be recreated during docker compose up"
            $ChecksPassed++
        }
    }
    catch {
        Log-Info "Network agentics_agentnet does not exist yet (will be created)"
        $ChecksPassed++
    }
}

# ============================================================================
# CHECK: Port Availability
# ============================================================================

if (-not $SkipPortCheck) {
    Log-Section "CHECKING PORT AVAILABILITY"
    
    $Ports = @{
        3000   = "Open WebUI"
        8787   = "Agent Dashboard"
        8788   = "Agentics Orchestrator"
        11434  = "Ollama"
        5678   = "n8n"
        5432   = "PostgreSQL"
        8765   = "Tools API"
        8001   = "Chroma"
        9998   = "Tika"
        9000   = "MinIO"
        9001   = "MinIO Console"
        3001   = "WAHA"
        9090   = "Prometheus"
        3002   = "Grafana"
        3100   = "Loki"
        8089   = "cAdvisor"
        5000   = "PostGraphile GraphQL"
    }
    
    foreach ($Port in $Ports.GetEnumerator()) {
        try {
            $Conn = New-Object System.Net.Sockets.TcpClient
            $Conn.Connect("127.0.0.1", $Port.Key)
            
            if ($Conn.Connected) {
                Log-Warn "Port $($Port.Key) ($($Port.Value)) is already in use"
                $Conn.Close()
                $ChecksFailed++
            }
        }
        catch {
            Log-Success "Port $($Port.Key) ($($Port.Value)) is available"
            $ChecksPassed++
        }
    }
}

# ============================================================================
# CHECK: Compose Validation
# ============================================================================

Log-Section "VALIDATING COMPOSE FILES"

Push-Location $ProjectRoot
try {
    $Validation = docker compose \
        -f "docker-compose.yml" \
        -f "docker-compose.lenovo-i9-cpu-npu.override.yml" \
        config 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Compose files are valid"
        Log-Verbose "Services: $(($Validation | grep -c 'container_name'))"
        $ChecksPassed++
    }
    else {
        Log-Error "Compose validation failed: $Validation"
        $ChecksFailed++
    }
}
catch {
    Log-Error "Compose validation error: $_"
    $ChecksFailed++
}
finally {
    Pop-Location
}

# ============================================================================
# CHECK: Hardware (Lenovo-specific)
# ============================================================================

Log-Section "CHECKING HARDWARE"

try {
    $Processor = Get-CimInstance Win32_Processor
    $ProcName = $Processor.Name
    $Cores = $Processor.NumberOfCores
    
    Log-Success "Processor: $ProcName ($Cores cores)"
    
    if ($ProcName -match "i9") {
        Log-Success "Intel i9 detected"
        $ChecksPassed++
    }
    elseif ($ProcName -match "i7|i5") {
        Log-Warn "Detected Intel $([regex]::Match($ProcName, 'i[57]').Value), but i9 expected"
        $ChecksPassed++
    }
    else {
        Log-Warn "Processor not an Intel Core i-series"
        $ChecksPassed++
    }
}
catch {
    Log-Warn "Could not detect processor: $_"
}

# ============================================================================
# SUMMARY
# ============================================================================

Log-Section "PRE-FLIGHT CHECK SUMMARY"

$TotalChecks = $ChecksPassed + $ChecksFailed

if ($ChecksFailed -eq 0) {
    Write-Host @Colors.Green "
╔════════════════════════════════════════════════════════════════╗
║  ✓ ALL CHECKS PASSED ($ChecksPassed/$TotalChecks)              ║
║                                                                ║
║  Ready to start Agentics Lenovo i9 stack!                      ║
║                                                                ║
║  Next step:                                                    ║
║    .\start-agentics-lenovo-i9-npu.ps1                          ║
╚════════════════════════════════════════════════════════════════╝
"
    exit 0
}
else {
    Write-Host @Colors.Yellow "
╔════════════════════════════════════════════════════════════════╗
║  ⚠  CHECKS COMPLETED WITH ISSUES ($ChecksFailed/$TotalChecks)   ║
║                                                                ║
║  Passed: $ChecksPassed                                        ║
║  Failed: $ChecksFailed                                        ║
║                                                                ║
║  Review errors above and fix before starting.                 ║
║  Some warnings may not block startup.                         ║
╚════════════════════════════════════════════════════════════════╝
"
    exit 1
}
