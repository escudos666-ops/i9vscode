FROM node:18-alpine

WORKDIR /app

# Install dependencies (no lockfile needed)
COPY package.json ./
RUN npm install --omit=dev

# Copy app code and static frontend
COPY server.js .
COPY public ./public

ENV NODE_ENV=production
ENV PORT=9000

HEALTHCHECK --interval=20s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:9000/health || exit 1

EXPOSE 9000
CMD ["node", "server.js"]
