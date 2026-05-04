FROM n8nio/n8n:latest

# ── Pre-configured by seller — customers do NOT need to set these ──
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_PORT=$PORT

USER root
RUN mkdir -p /workflows
COPY workflows/ /workflows/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER node
ENTRYPOINT ["/entrypoint.sh"]
