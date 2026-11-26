FROM node:22-bookworm-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-venv ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
COPY services/api/package.json ./services/api/package.json
COPY apps/admin/package.json ./apps/admin/package.json
RUN npm ci

COPY services/api ./services/api
COPY services/agents/pyproject.toml ./services/agents/pyproject.toml
COPY services/agents/anuvach_agents ./services/agents/anuvach_agents
COPY services/agents/workbench ./services/agents/workbench

RUN npm run build --workspace services/api \
    && python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install ./services/agents

COPY services/cloudrun-entrypoint.sh /usr/local/bin/cloudrun-entrypoint
RUN chmod 755 /usr/local/bin/cloudrun-entrypoint

EXPOSE 8080
CMD ["/usr/local/bin/cloudrun-entrypoint"]