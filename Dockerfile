# ---------- Stage 1: Build n8n ----------
FROM node:20-bullseye AS builder

# Required tools for native modules
RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*

WORKDIR /data

# Enable Corepack (manages pnpm automatically)
RUN corepack enable

# Clone latest n8n
RUN git clone https://github.com/n8n-io/n8n.git .

# Install deps & build
RUN pnpm install --frozen-lockfile
RUN pnpm build

# ---------- Stage 2: Runtime image ----------
FROM node:18-bullseye
ENV NODE_ENV=production N8N_PORT=5678 N8N_HOST=0.0.0.0 N8N_BASIC_AUTH_ACTIVE=false
WORKDIR /home/node
RUN npm install -g pnpm && mkdir -p /home/node/.n8n && chown -R node:node /home/node
COPY --from=builder /data /data
WORKDIR /data
USER node
EXPOSE 5678
VOLUME ["/home/node/.n8n"]
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5678/healthz || exit 1
CMD ["pnpm", "start"]
