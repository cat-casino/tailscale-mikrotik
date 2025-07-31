FROM alpine:3.19

RUN apk add --no-cache ca-certificates iproute2 iptables iptables-legacy openssh bash

RUN ln -sf /sbin/iptables-legacy /sbin/iptables && \
    ln -sf /sbin/ip6tables-legacy /sbin/ip6tables

COPY tailscale/tailscaled /usr/local/bin/
COPY tailscale/tailscale /usr/local/bin/
COPY tailscale.sh /usr/local/bin/
COPY sshd_config /etc/ssh/

EXPOSE 22
CMD ["/usr/local/bin/tailscale.sh"]
