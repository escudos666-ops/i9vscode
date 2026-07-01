#!/bin/bash
# Enhanced setup for OpenWebUI with full observability stack

set -euo pipefail

echo "🚀 OpenWebUI Enhanced Stack Setup"
echo "=================================="
echo ""

# Detect OS and set sed options accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE="-i.bak"
else
    SED_INPLACE="-i"
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env from .env.example..."
    cp .env.example .env
    echo "⚠️  IMPORTANT: Edit .env and update all secrets before deploying to production!"
    echo ""
    read -p "Press Enter to continue with default test secrets..."
fi

# Generate random passwords if using defaults
if grep -q "change-this-in-production" .env; then
    echo "🔐 Generating random secrets..."
    
    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        echo "❌ openssl not found. Please install openssl or manually update .env with secure secrets."
        exit 1
    fi
    
    sed "${SED_INPLACE}" "s/your-super-secret-key-change-this-in-production/$(openssl rand -base64 32)/g" .env || {
        echo "❌ Failed to update WEBUI_SECRET_KEY"
        exit 1
    }
    sed "${SED_INPLACE}" "s/your-jwt-secret-change-this-in-production/$(openssl rand -base64 32)/g" .env || {
        echo "❌ Failed to update WEBUI_JWT_SECRET"
        exit 1
    }
    sed "${SED_INPLACE}" "s/your-redis-password-change-this-in-production/$(openssl rand -base64 16)/g" .env || {
        echo "❌ Failed to update REDIS_PASSWORD"
        exit 1
    }
    sed "${SED_INPLACE}" "s/your-qdrant-api-key-change-this-in-production/$(openssl rand -base64 16)/g" .env || {
        echo "❌ Failed to update QDRANT_API_KEY"
        exit 1
    }
    sed "${SED_INPLACE}" "s/your-postgres-password-change-this-in-production/$(openssl rand -base64 16)/g" .env || {
        echo "❌ Failed to update POSTGRES_PASSWORD"
        exit 1
    }
    sed "${SED_INPLACE}" "s/your-grafana-admin-password/$(openssl rand -base64 12)/g" .env || {
        echo "❌ Failed to update GRAFANA_PASSWORD"
        exit 1
    }
    
    # Clean up backup files on macOS
    [ -f .env.bak ] && rm .env.bak
    
    echo "✅ Secrets generated successfully"
fi

# Pull images
echo "📥 Pulling latest images..."
if ! docker compose -f docker-compose-full.yml pull; then
    echo "❌ Failed to pull images"
    exit 1
fi

# Create directories for volumes
echo "📁 Creating configuration directories..."
mkdir -p grafana-dashboards

# Start services
echo "🚀 Starting services..."
if ! docker compose -f docker-compose-full.yml up -d; then
    echo "❌ Failed to start services"
    exit 1
fi

# Wait for services
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check health
echo ""
echo "🏥 Service Health Check:"
echo "========================"
docker compose -f docker-compose-full.yml ps

echo ""
echo "✅ Setup Complete!"
echo ""
echo "📱 Access your services:"
echo "  • OpenWebUI:   http://localhost:8080"
echo "  • Grafana:     http://localhost:3000"
echo "  • Prometheus:  http://localhost:9090"
echo "  • Loki:        http://localhost:3100"
echo "  • OpenSearch:  http://localhost:9200"
echo "  • Qdrant:      http://localhost:6333"
echo "  • Redis:       localhost:6379 (with password from .env)"
echo "  • PostgreSQL:  localhost:5432"
echo ""
echo "💡 Next steps:"
echo "  1. Open http://localhost:8080 and create an admin account"
echo "  2. Configure Ollama models in OpenWebUI"
echo "  3. Set up Grafana dashboards for monitoring"
echo "  4. Enable RAG for better conversation context"
echo ""
echo "📊 View logs:"
echo "  docker compose -f docker-compose-full.yml logs -f [service]"
echo ""
echo "🛑 Stop services:"
echo "  docker compose -f docker-compose-full.yml down"
