# Multi-stage build for optimized nginx frontend
# Stage 1: Build Node app (if needed for build step, currently just serves static)
FROM node:22-alpine AS builder
WORKDIR /app
COPY ./src ./src
# If you have a build script in the future, uncomment:
# COPY package*.json ./
# RUN npm ci && npm run build

# Stage 2: Serve with nginx
FROM nginx:1.27-alpine
WORKDIR /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files from builder (or source)
COPY --from=builder /app/src /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=5s \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
