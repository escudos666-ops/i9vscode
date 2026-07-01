.PHONY: help setup setup-full setup-ps setup-full-ps up up-full down logs health health-ps monitor monitor-ps backup clean dev prod custom-app-up custom-app-down

help:
	@echo "🐳 OpenWebUI Commands"
	@echo "===================="
	@echo ""
	@echo "Basic Stack (OpenWebUI only):"
	@echo "  make setup       - Initial setup (basic)"
	@echo "  make setup-ps    - Initial setup (basic, PowerShell)"
	@echo "  make up          - Start basic services"
	@echo ""
	@echo "Full Stack (OpenWebUI + Monitoring + Memory Tools):"
	@echo "  make setup-full  - Full setup with all tools"
	@echo "  make setup-full-ps - Full setup with all tools (PowerShell)"
	@echo "  make up-full     - Start full stack"
	@echo ""
	@echo "Management:"
	@echo "  make down        - Stop services"
	@echo "  make logs        - View live logs"
	@echo "  make health      - Check basic health"
	@echo "  make health-ps   - Check basic health (PowerShell)"
	@echo "  make monitor     - Monitor full stack (Prometheus, Grafana, Loki)"
	@echo "  make monitor-ps  - Monitor full stack (PowerShell)"
	@echo "  make backup      - Backup conversation data"
	@echo "  make custom-app-up   - Start custom frontend/backend starter app"
	@echo "  make custom-app-down - Stop custom frontend/backend starter app"
	@echo ""
	@echo "Development:"
	@echo "  make dev         - Start with debug logging"
	@echo "  make prod        - Start with production settings"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean       - Remove all volumes/containers (⚠️  data loss)"

setup:
	@if [ ! -f .env ]; then cp .env.example .env; echo "✅ Created .env"; fi
	docker compose pull
	@echo "✅ Setup complete. Run 'make up' to start"

setup-full:
	@bash ./setup-full.sh

setup-ps:
	powershell -ExecutionPolicy Bypass -File .\setup.ps1

setup-full-ps:
	powershell -ExecutionPolicy Bypass -File .\setup-full.ps1

up:
	docker compose up -d
	@echo "✅ Services started. Open http://localhost:8080"

up-full:
	docker compose -f docker-compose-full.yml up -d
	@echo "✅ Full stack started."
	@echo "   OpenWebUI: http://localhost:8080"
	@echo "   Grafana:   http://localhost:3000"
	@echo "   Prometheus: http://localhost:9090"

down:
	docker compose down
	@echo "✅ Services stopped"

logs:
	docker compose logs -f

health:
	@bash ./health.sh

health-ps:
	powershell -ExecutionPolicy Bypass -File .\health.ps1

monitor:
	@bash ./monitor-full.sh

monitor-ps:
	powershell -ExecutionPolicy Bypass -File .\monitor-full.ps1

backup:
	@bash ./backup.sh

clean:
	docker compose down -v
	@echo "⚠️  All volumes removed. Data is gone."

dev:
	WEBUI_DEBUG=true LOG_LEVEL=DEBUG docker compose up -d
	@echo "✅ Started in development mode"

prod:
	WEBUI_DEBUG=false LOG_LEVEL=INFO docker compose -f docker-compose-full.yml up -d
	@echo "✅ Started in production mode"

custom-app-up:
	docker compose -f docker-compose-custom-app.yml up -d --build
	@echo "✅ Custom app started. Frontend http://localhost:8090"

custom-app-down:
	docker compose -f docker-compose-custom-app.yml down
	@echo "✅ Custom app stopped."
