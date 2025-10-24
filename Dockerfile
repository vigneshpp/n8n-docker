# ------------------------------------------------------------
# Stage 1 — Build n8n from source (lightweight + ARMv7 compatible)
# ------------------------------------------------------------
FROM node:20-bookworm-slim AS builder

# Install minimal build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git python3 make g++ ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Enable Corepack (manages pnpm/yarn automatically)
RUN corepack enable

# Set working directory
WORKDIR /data

# Clone the latest n8n source
RUN git clone https://github.com/n8n-io/n8n.git .

# Install dependencies using pnpm (use lockfile for reproducibility)
RUN pnpm install --frozen-lockfile

# Build n8n (transpile TypeScript → JavaScript)
RUN pnpm build

# ------------------------------------------------------------
# Stage 2 — Runtime image
# ------------------------------------------------------------
FROM node:20-bookworm-slim

# Create non-root user
RUN addgroup --system n8n && adduser --system --ingroup n8n n8n

WORKDIR /home/n8n

# Copy built application from builder
COPY --from=builder /data /home/n8n/n8n

# Set environment variables
ENV NODE_ENV=production
ENV N8N_PORT=5678
ENV N8N_PATH=/home/n8n/n8n

# Expose port
EXPOSE 5678

# Switch to non-root user
USER n8n

# Default command
CMD ["node", "/home/n8n/n8n/packages/cli/bin/n8n"]
