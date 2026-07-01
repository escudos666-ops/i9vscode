# Open WebUI Agentic Capabilities

This workspace now exposes two tool servers that Open WebUI can use in Native Function Calling / Agentic Mode.

## What Your WebUI Agent Can Do

- Inspect business readiness: database health, connector status, and dashboard counts.
- Work with customers: search customers, create a customer, and open a customer profile.
- Work with optical prescriptions: store OD/OS prescription values for an existing customer.
- Work with inventory: list stock and create or update frame, lens, and accessory inventory items.
- Fill allowlisted local browser forms through the Playwright sidecar.

The business tools are intentionally narrow and explicit. They give the model real actions while keeping risky writes easy to audit and confirm in chat.

## Start The Agentic Stack

```powershell
docker compose --profile tools up -d --build
```

Useful checks:

```powershell
docker compose --profile tools ps
curl http://localhost:3001/openapi.json
curl http://localhost:8788/openapi.json
```

## Add Tools In Open WebUI

Open `http://localhost:8080`, then:

1. Go to `Admin Settings` -> `External Tools`.
2. Add an OpenAPI server for business tools:
   - URL from inside Docker: `http://agentic-business-tools:3001/openapi.json`
   - URL from the host, if needed: `http://host.docker.internal:3001/openapi.json`
3. Add an OpenAPI server for browser automation:
   - URL from inside Docker: `http://playwright-mcp:8788/openapi.json`
   - Auth: bearer token from `PLAYWRIGHT_MCP_API_KEY`
4. Go to the model settings and set Function Calling to Native / Agentic Mode.
5. Attach the new tools to the model or enable them for the chat.

## Good First Prompts

```text
What business tools do you have available? Check the dashboard and connector readiness.
```

```text
Search for customer "Jansen" and summarize what records are present.
```

```text
List inventory items that are at or below reorder level.
```

```text
Create a customer named Sara de Vries with email sara@example.com after checking for duplicates.
```

## Guardrails

- Confirm before creating customers, changing inventory, or storing prescription data.
- Do not use connector-dependent actions until `/api/connectors` says the connector is ready.
- Keep browser automation limited to the allowlisted hosts in `AUTOMATOR_ALLOWED_HOSTS`.
- Prefer strong tool-calling models for multi-step work. Small local models may see the tool list but still call tools unreliably.
