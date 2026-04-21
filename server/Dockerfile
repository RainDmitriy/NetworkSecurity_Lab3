FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssh-server \
    iputils-ping \
    tcpdump \
    iproute2 \
    net-tools \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd && \
    echo 'root:labpass' | chpasswd && \
    sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN echo '<h1>Protected Server</h1>' > /var/www/html/index.html

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
