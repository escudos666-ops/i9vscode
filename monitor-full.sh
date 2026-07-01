#!/bin/bash
# Monitoring and memory optimization script

echo "🔍 OpenWebUI Enhanced Stack Monitoring"
echo "======================================"
echo ""

echo "📊 Service Status:"
docker compose -f docker-compose-full.yml ps

echo ""
echo "💾 Storage Usage:"
echo "  Redis:"
docker compose -f docker-compose-full.yml exec -T redis redis-cli --raw info memory | grep used_memory_human || echo "    (unavailable)"
echo "  PostgreSQL (connections):"
docker compose -f docker-compose-full.yml exec -T postgres psql -U ${POSTGRES_USER:-webui} -d ${POSTGRES_DB:-openwebui} -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null || echo "    (not ready)"
echo "  Qdrant:"
curl -s http://localhost:6333/collections | jq '.result | length' 2>/dev/null && echo "    collections found" || echo "    (not available)"

echo ""
echo "🏥 Health Checks:"
echo -n "  Redis: "
docker compose -f docker-compose-full.yml exec -T redis redis-cli ping 2>/dev/null && echo "✅" || echo "❌"
echo -n "  PostgreSQL: "
docker compose -f docker-compose-full.yml exec -T postgres pg_isready -U ${POSTGRES_USER:-webui} 2>/dev/null && echo "✅" || echo "❌"
echo -n "  Qdrant: "
curl -s http://localhost:6333/health > /dev/null && echo "✅" || echo "❌"
echo -n "  OpenSearch: "
curl -s http://localhost:9200/_cluster/health > /dev/null && echo "✅" || echo "❌"
echo -n "  OpenWebUI: "
curl -s http://localhost:8080/health > /dev/null && echo "✅" || echo "❌"

echo ""
echo "📈 Resource Usage (Top 5):"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6

echo ""
echo "🔴 Recent Errors:"
docker compose -f docker-compose-full.yml logs --tail 20 2>/dev/null | grep -i error || echo "  None"

echo ""
echo "💡 Optimization Tips:"
echo "  • Monitor Grafana: http://localhost:3000"
echo "  • View logs: docker compose -f docker-compose-full.yml logs -f [service]"
echo "  • Check Loki: http://localhost:3100"
echo "  • Query OpenSearch: curl http://localhost:9200/_search"
