#!/bin/bash
# Quick setup and startup script for OpenWebUI + Ollama

set -euo pipefail

echo "🐳 OpenWebUI + Ollama Setup"
echo "============================"

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env from .env.example..."
    cp .env.example .env
    echo "⚠️  Edit .env and set WEBUI_SECRET_KEY and WEBUI_JWT_SECRET before running in production!"
fi

# Pull latest images
echo "📥 Pulling latest images..."
if ! docker compose pull; then
    echo "❌ Failed to pull images"
    exit 1
fi

# Start services
echo "🚀 Starting services..."
if ! docker compose up -d; then
    echo "❌ Failed to start services"
    exit 1
fi

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker compose ps --filter "health=healthy" | grep -q "postgres\|ollama\|open-webui"; then
        echo "✅ Services are ready!"
        break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo "⚠️  Services took longer than expected. They may still be starting..."
        echo "Check status with: docker compose ps"
    fi
    sleep 2
done

# Display URLs
echo ""
echo "📱 Access your services:"
echo "  • OpenWebUI: http://localhost:8080"
echo "  • Ollama API: http://localhost:11434"
echo ""
echo "💡 Next steps:"
echo "  1. Open http://localhost:8080 in your browser"
echo "  2. Create an admin account"
echo "  3. Go to Admin Settings → Models to configure Ollama"
echo ""
echo "🔍 View logs:"
echo "  docker compose logs -f ollama"
echo "  docker compose logs -f open-webui"
