#!/bin/bash
# Backup OpenWebUI and Ollama data volumes

set -euo pipefail

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "🔄 Backing up volumes..."

# Verify volumes exist
echo "  • Checking volumes..."
if ! docker volume ls --quiet | grep -q "ai-llm_ollama_data"; then
    echo "❌ Volume ai-llm_ollama_data not found"
    exit 1
fi

if ! docker volume ls --quiet | grep -q "ai-llm_webui_data"; then
    echo "❌ Volume ai-llm_webui_data not found"
    exit 1
fi

# Backup Ollama models
echo "  • Backing up Ollama data..."
if ! docker run --rm \
  -v ai-llm_ollama_data:/data \
  -v "$(pwd)/$BACKUP_DIR:/backup" \
  alpine tar czf "/backup/ollama_$TIMESTAMP.tar.gz" -C /data . 2>/dev/null; then
    echo "❌ Failed to backup Ollama data"
    exit 1
fi
echo "    ✅ Ollama backup complete: ollama_$TIMESTAMP.tar.gz"

# Backup OpenWebUI data
echo "  • Backing up OpenWebUI data..."
if ! docker run --rm \
  -v ai-llm_webui_data:/data \
  -v "$(pwd)/$BACKUP_DIR:/backup" \
  alpine tar czf "/backup/webui_$TIMESTAMP.tar.gz" -C /data . 2>/dev/null; then
    echo "❌ Failed to backup WebUI data"
    exit 1
fi
echo "    ✅ WebUI backup complete: webui_$TIMESTAMP.tar.gz"

echo ""
echo "✅ Backups completed in $BACKUP_DIR/"
ls -lh "$BACKUP_DIR" | tail -3

echo ""
echo "📋 To restore:"
echo "  # Restore Ollama:"
echo "  docker run --rm -v ai-llm_ollama_data:/data -v \$(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/ollama_$TIMESTAMP.tar.gz -C /data"
echo ""
echo "  # Restore WebUI:"
echo "  docker run --rm -v ai-llm_webui_data:/data -v \$(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/webui_$TIMESTAMP.tar.gz -C /data"
