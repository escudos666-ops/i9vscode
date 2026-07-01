#!/bin/bash
# Monitoring and troubleshooting script

set -euo pipefail

echo "🔍 OpenWebUI + Ollama Health Check"
echo "==================================="
echo ""

# Check if services are running
echo "📊 Service Status:"
docker compose ps

echo ""
echo "💾 Volume Usage:"
if docker compose ps | grep -q "ollama"; then
    docker compose exec ollama du -sh /root/.ollama 2>/dev/null || echo "  Ollama: (not ready)"
else
    echo "  Ollama: (not running)"
fi

if docker compose ps | grep -q "open-webui\|webui"; then
    docker compose exec open-webui du -sh /app/backend/data 2>/dev/null || echo "  WebUI: (not ready)"
else
    echo "  WebUI: (not running)"
fi

echo ""
echo "🏥 Health Checks:"
echo -n "  Ollama: "
if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy or unreachable"
fi

echo -n "  WebUI: "
if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy or unreachable"
fi

echo ""
echo "📈 Resource Usage (last 10 containers):"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | tail -10 || echo "  (No containers running)"

echo ""
echo "🔴 Recent Errors:"
echo "  Ollama errors:"
if docker compose logs ollama --tail 10 2>/dev/null | grep -iE "error|fatal|panic" > /dev/null 2>&1; then
    docker compose logs ollama --tail 10 2>/dev/null | grep -iE "error|fatal|panic" | head -3
else
    echo "    None detected"
fi

echo ""
echo "  WebUI errors:"
if docker compose logs open-webui --tail 10 2>/dev/null | grep -iE "error|fatal|exception" > /dev/null 2>&1; then
    docker compose logs open-webui --tail 10 2>/dev/null | grep -iE "error|fatal|exception" | head -3
else
    echo "    None detected"
fi

echo ""
echo "💡 Common fixes:"
echo "  • Restart services: docker compose restart"
echo "  • Check full logs: docker compose logs -f [service]"
echo "  • Full reset: docker compose down -v && docker compose up"
echo "  • Check disk space: df -h"
