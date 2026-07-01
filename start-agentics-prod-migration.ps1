param(
    [switch]$WithVpn,
    [switch]$StopKubernetes
)

$ErrorActionPreference = "Stop"

Set-Location "C:\DeerpShit\Agentics"

Write-Host "[Agentics Migration] Creating safety folders..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path ".\agent-workspace", ".\secrets", ".\monitoring", ".\backups\before-prod-migration" | Out-Null

Write-Host "[Agentics Migration] Backing up current Docker state..." -ForegroundColor Cyan
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | Out-File ".\backups\before-prod-migration\containers.txt"
docker volume ls | Out-File ".\backups\before-prod-migration\volumes.txt"
docker network ls | Out-File ".\backups\before-prod-migration\networks.txt"
docker compose ls | Out-File ".\backups\before-prod-migration\compose-projects.txt"

if (!(Test-Path ".\.env")) {
    if (Test-Path ".\.env.prod.example") {
        Copy-Item ".\.env.prod.example" ".\.env"
    } else {
        Set-Content ".\.env" "POSTGRES_PASSWORD=your-postgres-password-change-this-in-production"
    }
}

$envContent = Get-Content ".\.env" -ErrorAction SilentlyContinue
$postgresPassword = ($envContent | Where-Object { $_ -match "^POSTGRES_PASSWORD=" } | Select-Object -First 1) -replace "^POSTGRES_PASSWORD=", ""

if ([string]::IsNullOrWhiteSpace($postgresPassword)) {
    $postgresPassword = "your-postgres-password-change-this-in-production"
}

Set-Content ".\secrets\postgres_password.txt" $postgresPassword -NoNewline

if (!(Test-Path ".\secrets\minio_root_password.txt")) {
    Set-Content ".\secrets\minio_root_password.txt" "change_this_minio_password" -NoNewline
}

if (!(Test-Path ".\secrets\grafana_admin_password.txt")) {
    Set-Content ".\secrets\grafana_admin_password.txt" "change_this_grafana_password" -NoNewline
}

Write-Host "[Agentics Migration] Validating production compose + migration override..." -ForegroundColor Cyan
docker compose `
  -f ".\docker-compose.agentics.prod.yml" `
  -f ".\docker-compose.agentics.prod.migration.override.yml" `
  config | Out-Null

Write-Host "[Agentics Migration] Stopping old non-Kubernetes containers that conflict with production ports..." -ForegroundColor Cyan

$old = @(
    "openwebui",
    "openwebui-extension-service",
    "postgres-service",
    "ollama-service",
    "n8n",
    "chroma",
    "grafana",
    "tika",
    "waha",
    "open-terminal",
    "openclaw-gateway",
    "openclaw-mcp",
    "agentics-dashboard"
)

foreach ($name in $old) {
    $exists = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $name }
    if ($exists) {
        Write-Host "Stopping/removing: $name" -ForegroundColor DarkYellow
        docker stop $name 2>$null | Out-Null
        docker rm $name 2>$null | Out-Null
    }
}

if ($StopKubernetes) {
    Write-Host "[Agentics Migration] StopKubernetes was requested." -ForegroundColor Yellow
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        kubectl scale deployment --all --replicas=0 -n agentics 2>$null
        kubectl scale deployment --all --replicas=0 -n agentics-k8s-staging 2>$null
        kubectl scale deployment --all --replicas=0 -n default 2>$null
    } else {
        Write-Host "kubectl not found; skipping Kubernetes scaling." -ForegroundColor Yellow
    }
} else {
    Write-Host "[Agentics Migration] Leaving Kubernetes containers alone." -ForegroundColor Yellow
}

Write-Host "[Agentics Migration] Starting production stack with existing volumes..." -ForegroundColor Cyan

$composeArgs = @(
    "compose",
    "-f", ".\docker-compose.agentics.prod.yml",
    "-f", ".\docker-compose.agentics.prod.migration.override.yml"
)

if ($WithVpn) {
    $composeArgs += @("--profile", "vpn")
}

$composeArgs += @("up", "-d", "--build", "--remove-orphans")
docker @composeArgs

Write-Host "[Agentics Migration] Status:" -ForegroundColor Green
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host ""
Write-Host "Open WebUI:       http://127.0.0.1:3000" -ForegroundColor Green
Write-Host "Headful Browser:  http://127.0.0.1:6080" -ForegroundColor Green
Write-Host "n8n:              http://127.0.0.1:5678" -ForegroundColor Green
Write-Host "Grafana:          http://127.0.0.1:3002" -ForegroundColor Green
