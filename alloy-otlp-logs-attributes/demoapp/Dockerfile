FROM docker.io/library/debian:bookworm-slim

RUN apt update && \
    apt install -y jq curl

COPY sendlog.sh /root

CMD ["sh", "-c", "exec /root/sendlog.sh"]
