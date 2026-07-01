# ============================================================================
# START UNIFIED DASHBOARD
# ============================================================================
# PowerShell script to build and start the unified dashboard
#
# Usage:
#   .\start-unified-dashboard.ps1
#
# ============================================================================

param(
    [switch]$Build = $false,
    [switch]$OnlyUp = $false,
    [switch]$OnlyDown = $false,
    [switch]$Logs = $false,
    [switch]$Health = $false
)

function Log-Info { Write-Host -ForegroundColor Cyan "ℹ️  $args" }
function Log-Success { Write-Host -ForegroundColor Green "✓ $args" }
function Log-Warn { Write-Host -ForegroundColor Yellow "⚠️  $args" }
function Log-Error { Write-Host -ForegroundColor Red "✗ $args" }
function Log-Section { 
    Write-Host "`n"
    Write-Host -ForegroundColor Blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host -ForegroundColor Blue "  $args"
    Write-Host -ForegroundColor Blue "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

$ProjectRoot = $PSScriptRoot

# ============================================================================
# FUNCTIONS
# ============================================================================

function Build-Images {
    Log-Section "BUILDING DASHBOARD IMAGES"
    
    $BackendDir = Join-Path $ProjectRoot "agentics-unified-dashboard/backend"
    $FrontendDir = Join-Path $ProjectRoot "agentics-unified-dashboard/frontend"
    
    # Build backend
    Log-Info "Building backend image..."
    docker build -f "$BackendDir/Dockerfile" -t unified-dashboard-backend:latest "$BackendDir"
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Backend image built"
    } else {
        Log-Error "Backend build failed"
        exit 1
    }
    
    # Build frontend
    Log-Info "Building frontend image..."
    docker build -f "$FrontendDir/Dockerfile" -t unified-dashboard-frontend:latest "$FrontendDir"
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Frontend image built"
    } else {
        Log-Error "Frontend build failed"
        exit 1
    }
}

function Start-Dashboard {
    Log-Section "STARTING UNIFIED DASHBOARD"
    
    Push-Location $ProjectRoot
    try {
        Log-Info "Starting with docker compose..."
        docker compose `
            -f docker-compose.yml `
            -f docker-compose.lenovo-i9-cpu-npu.override.yml `
            -f docker-compose.unified-dashboard.override.yml `
            up -d 2>&1 | Select-String -Pattern "Creating|Created|Starting|Started|Up|Error" -ErrorAction SilentlyContinue
        
        Log-Success "Dashboard started"
        
        # Wait for services
        Log-Info "Waiting for services to be healthy (30s)..."
        Start-Sleep -Seconds 30
        
    } finally {
        Pop-Location
    }
}

function Stop-Dashboard {
    Log-Section "STOPPING UNIFIED DASHBOARD"
    
    Push-Location $ProjectRoot
    try {
        docker compose `
            -f docker-compose.yml `
            -f docker-compose.lenovo-i9-cpu-npu.override.yml `
            -f docker-compose.unified-dashboard.override.yml `
            down -v
        
        Log-Success "Dashboard stopped"
    } finally {
        Pop-Location
    }
}

function Show-Status {
    Log-Section "DASHBOARD STATUS"
    
    Push-Location $ProjectRoot
    try {
        docker compose `
            -f docker-compose.yml `
            -f docker-compose.lenovo-i9-cpu-npu.override.yml `
            -f docker-compose.unified-dashboard.override.yml `
            ps
    } finally {
        Pop-Location
    }
}

function Show-Logs {
    Log-Section "DASHBOARD LOGS"
    
    Push-Location $ProjectRoot
    try {
        docker compose `
            -f docker-compose.yml `
            -f docker-compose.lenovo-i9-cpu-npu.override.yml `
            -f docker-compose.unified-dashboard.override.yml `
            logs -n 50 --timestamps
    } finally {
        Pop-Location
    }
}

function Check-Health {
    Log-Section "HEALTH CHECKS"
    
    $endpoints = @{
        "Backend Health"        = "http://127.0.0.1:9000/health"
        "Backend Services"      = "http://127.0.0.1:9000/api/services/health"
        "Dashboard Summary"     = "http://127.0.0.1:9000/api/dashboard/summary"
        "Frontend"              = "http://127.0.0.1:9999"
    }
    
    foreach ($endpoint in $endpoints.GetEnumerator()) {
        try {
            $response = Invoke-RestMethod $endpoint.Value -TimeoutSec 5 -ErrorAction Stop
            Log-Success "$($endpoint.Key): OK"
        } catch {
            Log-Warn "$($endpoint.Key): FAILED - $($_.Exception.Message)"
        }
    }
}

# ============================================================================
# MAIN
# ============================================================================

Log-Section "AGENTICS UNIFIED DASHBOARD"

if ($OnlyDown) {
    Stop-Dashboard
    exit 0
}

if ($OnlyUp) {
    Start-Dashboard
    Show-Status
    exit 0
}

if ($Logs) {
    Show-Logs
    exit 0
}

if ($Health) {
    Check-Health
    exit 0
}

# Default: full startup
if ($Build) {
    Build-Images
}

Start-Dashboard
Show-Status
Check-Health

Log-Section "DASHBOARD RUNNING"
Log-Success "Frontend:  http://localhost:9999"
Log-Success "Backend:   http://localhost:9000/api"
Log-Success "WebSocket: ws://localhost:9000"

Write-Host "`n"
