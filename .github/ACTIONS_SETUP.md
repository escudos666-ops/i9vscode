# GitHub Actions Setup Guide

## Overview
The workflow automates Docker image building, testing, and pushing on every push to `main` and `develop` branches, plus PR checks.

## Required Setup

### 1. GitHub Secrets
Navigate to **Settings → Secrets and variables → Actions** and verify:
- `GITHUB_TOKEN` — automatically available; used for GHCR access

### 2. Optional: Docker Hub Push
To push to Docker Hub instead of GHCR, add:
- `DOCKERHUB_USERNAME` — your Docker Hub username
- `DOCKERHUB_TOKEN` — Docker Hub access token (create at hub.docker.com/settings/security)

Update the workflow to use:
```yaml
registry: docker.io
username: ${{ secrets.DOCKERHUB_USERNAME }}
password: ${{ secrets.DOCKERHUB_TOKEN }}
```

### 3. Optional: Deploy on Push
Add a deployment step after successful builds:
```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: |
    # SSH into your server and pull new images
    ssh -i ${{ secrets.DEPLOY_KEY }} user@host << 'EOF'
      cd /app
      docker compose pull
      docker compose up -d
    EOF
```

## Workflow Jobs

### Build
- Builds `agentic-business-tools` and `playwright-mcp` images
- Pushes to GHCR on push events (automatic via PR metadata)
- Uses layer caching to speed up rebuilds

### Test
- Runs the built `agentic-business-tools` image
- Validates health endpoint at `GET /api/health`
- Fails if service doesn't become healthy in 60 seconds

### Security Scan
- Runs Trivy vulnerability scanner on Docker images
- Uploads results to GitHub Security tab for visibility
- Runs only on push events (not PRs by default)

### Compose Validation
- Validates `docker-compose.yml` syntax
- Checks for documented environment variables

## Local Testing

Run the workflow locally with [Act](https://github.com/nektos/act):
```bash
act push -j build
act push -j test
```

## Customization

### Add Node.js Linting
```yaml
- name: Lint code
  run: |
    cd custom-app/backend
    npm ci
    npm run lint
```

### Add Python Tests
For the playwright-mcp service:
```yaml
- name: Run Python tests
  run: |
    cd openwebui-browser-automator
    python -m pytest tests/
```

### Push to Multiple Registries
```yaml
images: |
  docker.io/${{ secrets.DOCKERHUB_USERNAME }}/agentic-business-tools
  ghcr.io/${{ github.repository }}/agentic-business-tools
```
