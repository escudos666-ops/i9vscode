param(
    [switch]$WithVpn
)

$ErrorActionPreference = "Stop"

Set-Location "C:\DeerpShit\Agentics"

Write-Host "[Agentics Prod] Creating folders..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path ".\agent-workspace", ".\secrets", ".\monitoring", ".\backups\before-prod-switch" | Out-Null

Write-Host "[Agentics Prod] Backing up current Docker state..." -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | Out-File ".\backups\before-prod-switch\containers.txt"
docker volume ls | Out-File ".\backups\before-prod-switch\volumes.txt"
docker network ls | Out-File ".\backups\before-prod-switch\networks.txt"
docker compose ls | Out-File ".\backups\before-prod-switch\compose-projects.txt"

if (!(Test-Path ".\.env")) {
    Copy-Item ".\.env.prod.example" ".\.env"
    Write-Host "[Agentics Prod] Created .env from template. Edit it later for stronger passwords." -ForegroundColor Yellow
}

# Read .env fallback password for secret files
$envContent = Get-Content ".\.env" -ErrorAction SilentlyContinue
$postgresPassword = ($envContent | Where-Object { $_ -match "^POSTGRES_PASSWORD=" } | Select-Object -First 1) -replace "^POSTGRES_PASSWORD=", ""
if ([string]::IsNullOrWhiteSpace($postgresPassword)) { $postgresPassword = "change_this_postgres_password" }

if (!(Test-Path ".\secrets\postgres_password.txt")) { Set-Content ".\secrets\postgres_password.txt" $postgresPassword -NoNewline }
if (!(Test-Path ".\secrets\minio_root_password.txt")) { Set-Content ".\secrets\minio_root_password.txt" "change_this_minio_password" -NoNewline }
if (!(Test-Path ".\secrets\grafana_admin_password.txt")) { Set-Content ".\secrets\grafana_admin_password.txt" "change_this_grafana_password" -NoNewline }

Write-Host "[Agentics Prod] Stopping known old/dev containers without deleting volumes..." -ForegroundColor Cyan

$keep = @(
    "agentics-open-webui",
    "agentics-ollama",
    "agentics-postgres",
    "agentics-redis",
    "agentics-chroma",
    "agentics-tika",
    "agentics-tools-api",
    "agentics-open-terminal",
    "agentics-python-sandbox",
    "agentics-playwright-mcp",
    "agentics-browser-vnc",
    "agentics-n8n",
    "agentics-minio",
    "agentics-prometheus",
    "agentics-loki",
    "agentics-grafana",
    "agentics-tailscale"
)

$patterns = "open-webui|ollama|chroma|tika|minio|n8n|postgres|redis|grafana|prometheus|loki|playwright|browser|terminal|tools-api|agentics|waha|postgraphile|adminer"

$old = docker ps -a --format "{{.Names}}" | Where-Object {
    ($_ -match $patterns) -and ($keep -notcontains $_)
}

foreach ($name in $old) {
    Write-Host "Stopping/removing old container: $name" -ForegroundColor DarkYellow
    docker stop $name 2>$null | Out-Null
    docker rm $name 2>$null | Out-Null
}

Write-Host "[Agentics Prod] Validating compose..." -ForegroundColor Cyan
docker compose -f ".\docker-compose.agentics.prod.yml" config | Out-Null

if ($WithVpn) {
    Write-Host "[Agentics Prod] Starting production stack with VPN profile..." -ForegroundColor Cyan
    docker compose -f ".\docker-compose.agentics.prod.yml" --profile vpn up -d --build --remove-orphans
} else {
    Write-Host "[Agentics Prod] Starting production stack..." -ForegroundColor Cyan
    docker compose -f ".\docker-compose.agentics.prod.yml" up -d --build --remove-orphans
}

Write-Host "[Agentics Prod] Pulling local models..." -ForegroundColor Cyan
docker exec agentics-ollama ollama pull llama3.1
docker exec agentics-ollama ollama pull llama3.2:3b
docker exec agentics-ollama ollama pull qwen2.5-coder:7b
docker exec agentics-ollama ollama pull nomic-embed-text

Write-Host "[Agentics Prod] Status:" -ForegroundColor Green
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host ""
Write-Host "Open WebUI:      http://127.0.0.1:3000" -ForegroundColor Green
Write-Host "Headful Browser: http://127.0.0.1:6080" -ForegroundColor Green
Write-Host "n8n:             http://127.0.0.1:5678" -ForegroundColor Green
Write-Host "Grafana:         http://127.0.0.1:3002" -ForegroundColor Green
