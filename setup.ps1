$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

Write-Host "OpenWebUI + Ollama setup (PowerShell)"
Write-Host "====================================="

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example"
}

Write-Host "Pulling images..."
docker compose pull

Write-Host "Starting services..."
docker compose up -d

Write-Host "Current status:"
docker compose ps

Write-Host ""
Write-Host "OpenWebUI: http://localhost:8080"
Write-Host "Ollama:    http://localhost:11434"
