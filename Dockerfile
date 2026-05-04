FROM n8nio/n8n:latest

ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https

USER root
RUN apt-get update && apt-get install -y --no-install-recommends gosu && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /workflows
COPY workflows/ /workflows/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
