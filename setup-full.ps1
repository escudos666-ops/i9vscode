$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

function New-RandomSecret([int]$bytes = 32) {
    $buffer = New-Object byte[] $bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
    return [Convert]::ToBase64String($buffer)
}

Write-Host "OpenWebUI full-stack setup (PowerShell)"
Write-Host "======================================="

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example"
}

$envText = Get-Content ".env" -Raw
$replacements = @{
    "your-super-secret-key-change-this-in-production" = (New-RandomSecret 32)
    "your-jwt-secret-change-this-in-production"       = (New-RandomSecret 32)
    "your-redis-password-change-this-in-production"   = (New-RandomSecret 16)
    "your-qdrant-api-key-change-this-in-production"   = (New-RandomSecret 16)
    "your-postgres-password-change-this-in-production"= (New-RandomSecret 16)
    "your-grafana-admin-password"                     = (New-RandomSecret 12)
}

foreach ($key in $replacements.Keys) {
    if ($envText.Contains($key)) {
        $envText = $envText.Replace($key, $replacements[$key])
    }
}

Set-Content ".env" $envText -Encoding UTF8

if (-not (Test-Path "grafana-dashboards")) {
    New-Item -ItemType Directory -Path "grafana-dashboards" | Out-Null
}

Write-Host "Pulling images..."
docker compose -f docker-compose-full.yml pull

Write-Host "Starting full stack..."
docker compose -f docker-compose-full.yml up -d

Write-Host "Current status:"
docker compose -f docker-compose-full.yml ps

Write-Host ""
Write-Host "OpenWebUI:   http://localhost:8080"
Write-Host "Grafana:     http://localhost:3000"
Write-Host "Prometheus:  http://localhost:9090"
Write-Host "Loki:        http://localhost:3100"
Write-Host "OpenSearch:  http://localhost:9200"
Write-Host "Qdrant:      http://localhost:6333"
Write-Host "Ollama:      http://localhost:11434"
