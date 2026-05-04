FROM n8nio/n8n:latest

USER root
RUN mkdir -p /workflows
COPY workflows/ /workflows/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER node
ENTRYPOINT ["/entrypoint.sh"]
