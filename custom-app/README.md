# Custom Chatbot Starter (Frontend + Backend)

This starter adds your own app stack next to OpenWebUI:

- `chatbot-frontend` at `http://localhost:8090`
- `chatbot-backend` at `http://localhost:3001`
- `ollama` at `http://localhost:11434`

## Start

```powershell
docker compose -f docker-compose-custom-app.yml up -d --build
```

## Stop

```powershell
docker compose -f docker-compose-custom-app.yml down
```

## API

- `GET /api/health`
- `GET /openapi.json` for Open WebUI External Tools
- `GET /api/agent-capabilities`
- `GET /api/business/dashboard`
- `GET /api/connectors`
- `GET /api/customers?search=...`
- `POST /api/customers`
- `GET /api/customers/:id`
- `POST /api/customers/:id/prescriptions`
- `GET /api/inventory`
- `POST /api/inventory`
- `POST /api/chat` with JSON body:

```json
{
  "message": "Hello"
}
```

For Open WebUI setup, see `../AGENTIC-WEBUI.md`.
