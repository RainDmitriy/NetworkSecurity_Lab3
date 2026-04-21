FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    iputils-ping \
    curl \
    netcat-openbsd \
    openssh-client \
    sshpass \
    nmap \
    iproute2 \
    tcpdump \
    hping3 \
    telnet \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
