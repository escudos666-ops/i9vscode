$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

function Test-Http([string]$url) {
    try {
        Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 | Out-Null
        return $true
    } catch {
        return $false
    }
}

Write-Host "OpenWebUI full-stack monitor"
Write-Host "============================"

Write-Host "Service status:"
docker compose -f docker-compose-full.yml ps

Write-Host ""
Write-Host "Endpoint checks:"
Write-Host ("  OpenWebUI:  {0}" -f ($(if (Test-Http "http://localhost:8080/health") { "OK" } else { "FAIL" })))
Write-Host ("  Ollama:     {0}" -f ($(if (Test-Http "http://localhost:11434/api/tags") { "OK" } else { "FAIL" })))
Write-Host ("  Qdrant:     {0}" -f ($(if (Test-Http "http://localhost:6333/health") { "OK" } else { "FAIL" })))
Write-Host ("  OpenSearch: {0}" -f ($(if (Test-Http "http://localhost:9200/_cluster/health") { "OK" } else { "FAIL" })))
Write-Host ("  Prometheus: {0}" -f ($(if (Test-Http "http://localhost:9090/-/healthy") { "OK" } else { "FAIL" })))
Write-Host ("  Grafana:    {0}" -f ($(if (Test-Http "http://localhost:3000/api/health") { "OK" } else { "FAIL" })))
Write-Host ("  Loki:       {0}" -f ($(if (Test-Http "http://localhost:3100/ready") { "OK" } else { "FAIL" })))

Write-Host ""
Write-Host "Resource usage:"
docker stats --no-stream --format "table {{.Container}}`t{{.CPUPerc}}`t{{.MemUsage}}" | Select-Object -First 12
