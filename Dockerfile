FROM n8nio/n8n:latest

# ── Pre-configured by seller — customers do NOT need to set these ──
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https
ENV N8N_BASIC_AUTH_ACTIVE=true

USER root
RUN apk add --no-cache su-exec && \
    mkdir -p /workflows
COPY workflows/ /workflows/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Stay as root — entrypoint fixes volume permissions then drops to node
ENTRYPOINT ["/entrypoint.sh"]
