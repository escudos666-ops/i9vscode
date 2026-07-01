$ErrorActionPreference = "Stop"
Write-Host "=== Agentics Installer Part 1: files ===" -ForegroundColor Cyan

@"
POSTGRES_USER=admin
POSTGRES_PASSWORD=secret_password
POSTGRES_DB=project_db
MINIO_ROOT_USER=minio_admin
MINIO_ROOT_PASSWORD=minio_secret_password
WAHA_API_KEY=change-this-waha-api-key
WAHA_DASHBOARD_USERNAME=admin
WAHA_DASHBOARD_PASSWORD=change-this-waha-dashboard-password
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=ChangeThisGrafanaPassword123!
N8N_ENCRYPTION_KEY=agentics-local-encryption-key-change-later-1234567890
WEBHOOK_URL=http://localhost:5678/
"@ | Set-Content -Encoding UTF8 ".env"

@"
.env
.env.*
!.env.example
*.db
*.sqlite
*.sqlite3
*.sqlite-shm
*.sqlite-wal
*.db-shm
*.db-wal
dump.rdb
data/
postgres-data/
ollama/
backups/
test-reports/
vault/
.cache/
node_modules/
config/webui/
"@ | Set-Content -Encoding UTF8 ".gitignore"

New-Item -ItemType Directory -Force -Path ".\dashboard",".\n8n-imports",".\scripts",".\data",".\config" | Out-Null

@"
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    networks: [agentnet]
    ports: ["11434:11434"]
    volumes: ["./ollama:/root/.ollama"]

  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: openwebui
    restart: unless-stopped
    networks: [agentnet]
    ports: ["3000:8080"]
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - OLLAMA_API_BASE_URL=http://ollama:11434
      - WEBUI_SECRET_KEY=agentics-local-webui-secret-change-me
    depends_on: [ollama]
    volumes: ["./config/webui:/app/backend/data"]

  postgres:
    image: postgres:16
    container_name: postgres
    restart: unless-stopped
    networks: [agentnet]
    environment:
      POSTGRES_USER: `${POSTGRES_USER:-admin}
      POSTGRES_PASSWORD: `${POSTGRES_PASSWORD:-secret_password}
      POSTGRES_DB: `${POSTGRES_DB:-project_db}
    ports: ["5432:5432"]
    volumes: ["./data/postgres:/var/lib/postgresql/data"]

  redis:
    image: redis:7
    container_name: redis
    restart: unless-stopped
    networks: [agentnet]
    ports: ["6379:6379"]
    volumes: ["./data/redis:/data"]

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    networks: [agentnet]
    ports: ["5678:5678"]
    environment:
      - N8N_ENCRYPTION_KEY=`${N8N_ENCRYPTION_KEY}
      - WEBHOOK_URL=`${WEBHOOK_URL}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=`${POSTGRES_DB}
      - DB_POSTGRESDB_USER=`${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=`${POSTGRES_PASSWORD}
    depends_on: [postgres, redis, ollama]
    volumes:
      - ./data/n8n:/home/node/.n8n
      - ./n8n-imports:/imports

  chroma:
    image: chromadb/chroma:latest
    container_name: chroma
    restart: unless-stopped
    networks: [agentnet]
    ports: ["8000:8000"]
    volumes: ["./data/chroma:/chroma/chroma"]

  tika:
    image: apache/tika:latest-full
    container_name: tika
    restart: unless-stopped
    networks: [agentnet]
    ports: ["9998:9998"]

  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    networks: [agentnet]
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: `${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: `${MINIO_ROOT_PASSWORD}
    ports: ["9000:9000", "9001:9001"]
    volumes: ["./data/minio:/data"]

  waha:
    image: devlikeapro/waha:latest
    container_name: waha
    restart: unless-stopped
    networks: [agentnet]
    ports: ["3001:3000"]
    environment:
      - WAHA_API_KEY=`${WAHA_API_KEY}
      - WAHA_DASHBOARD_USERNAME=`${WAHA_DASHBOARD_USERNAME}
      - WAHA_DASHBOARD_PASSWORD=`${WAHA_DASHBOARD_PASSWORD}
    volumes: ["./data/waha:/app/.sessions"]

  postgraphile:
    image: graphile/postgraphile:latest
    container_name: postgraphile
    restart: unless-stopped
    networks: [agentnet]
    ports: ["5000:5000"]
    command: ["--connection","postgres://admin:secret_password@postgres:5432/project_db","--host","0.0.0.0","--port","5000","--schema","public","--watch","--enhance-graphiql","--cors"]
    depends_on: [postgres]

  adminer:
    image: adminer:latest
    container_name: adminer
    restart: unless-stopped
    networks: [agentnet]
    ports: ["8088:8080"]
    depends_on: [postgres]

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    networks: [agentnet]
    ports: ["3002:3000"]
    environment:
      - GF_SECURITY_ADMIN_USER=`${GRAFANA_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=`${GRAFANA_ADMIN_PASSWORD}
    volumes: ["./data/grafana:/var/lib/grafana"]

  agentics-dashboard:
    image: nginx:alpine
    container_name: agentics-dashboard
    restart: unless-stopped
    networks: [agentnet]
    ports: ["8787:80"]
    volumes: ["./dashboard:/usr/share/nginx/html:ro"]

networks:
  agentnet:
    driver: bridge
"@ | Set-Content -Encoding UTF8 "docker-compose.yml"

@"
<!doctype html>
<html>
<head><title>Agentics Control Room</title></head>
<body style="font-family:Arial;background:#101418;color:#e8eef5;padding:30px">
<h1>Agentics Control Room</h1>
<p><a href="http://localhost:3000" target="_blank">Open WebUI</a></p>
<p><a href="http://localhost:5678" target="_blank">n8n</a></p>
<p><a href="http://localhost:3001/dashboard/" target="_blank">WAHA</a></p>
<p><a href="http://localhost:5000/graphiql" target="_blank">PostGraphile</a></p>
<p><a href="http://localhost:8088" target="_blank">Adminer</a></p>
<p><a href="http://localhost:9001" target="_blank">MinIO</a></p>
<p><a href="http://localhost:3002" target="_blank">Grafana</a></p>
<p><a href="http://localhost:11434/api/tags" target="_blank">Ollama API</a></p>
</body>
</html>
"@ | Set-Content -Encoding UTF8 ".\dashboard\index.html"

Write-Host "Files created." -ForegroundColor Green
