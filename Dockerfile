# --- STAGE 1: Build 3proxy from local sources ---
FROM alpine:3.19 AS build-3proxy

RUN apk add --no-cache \
      build-base \
      openssl-dev \
      zlib-dev \
      linux-headers \
      make

WORKDIR /build

# копируем ваш локальный каталог 3proxy
COPY 3proxy/ . 

# собираем по Makefile.Linux
RUN make -f Makefile.Linux all \
    && mkdir -p /out/bin \
    && cp bin/3proxy /out/bin/3proxy

# --- STAGE 2: Runtime image with Tailscale + 3proxy ---
FROM alpine:3.19

RUN apk add --no-cache \
      ca-certificates \
      iproute2 \
      iptables \
      iptables-legacy \
      openssh \
      openssl \
      zlib

RUN ln -sf /sbin/iptables-legacy /sbin/iptables && \
    ln -sf /sbin/ip6tables-legacy /sbin/ip6tables

# копируем 3proxy-бинарь
COPY --from=build-3proxy /out/bin/3proxy /usr/local/bin/3proxy

# копируем Tailscale и helpers
COPY tailscale/tailscaled   /usr/local/bin/tailscaled
COPY tailscale/tailscale    /usr/local/bin/tailscale
COPY tailscale.sh           /usr/local/bin/tailscale.sh
COPY sshd_config            /etc/ssh/sshd_config
COPY 3proxy.cfg             /etc/3proxy/3proxy.cfg

EXPOSE 22 3128

CMD ["/bin/sh", "-c", "\
    /usr/local/bin/tailscale.sh & \
    exec /usr/local/bin/3proxy /etc/3proxy/3proxy.cfg \
"]
