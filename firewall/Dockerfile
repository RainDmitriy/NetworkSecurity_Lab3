FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    iptables \
    iproute2 \
    iputils-ping \
    tcpdump \
    net-tools \
    netcat-openbsd \
    conntrack \
    curl \
    vim-tiny \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --set iptables /usr/sbin/iptables-legacy && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

COPY entrypoint.sh /opt/entrypoint.sh
COPY iptables-rules.sh /opt/iptables-rules.sh
RUN chmod +x /opt/entrypoint.sh /opt/iptables-rules.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
