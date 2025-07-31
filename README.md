# Tailscale Container for MikroTik (ARM64)

This guide provides clear and simple steps to build a minimal Tailscale container image for MikroTik (ARM64) using macOS.

## Step-by-Step Guide

### 1. Install Dependencies (macOS)

```sh
brew install colima docker docker-buildx go upx git
colima start
docker context use colima
```
### 2. Clone the Repository and Tailscale Sources
```sh
git clone https://github.com/<your-org>/tailscale-mikrotik.git
cd tailscale-mikrotik
git clone --depth 1 --branch v1.78.1 https://github.com/tailscale/tailscale.git

```
### 3. Build ARM64 Binaries for Tailscale
```sh
cd tailscale
GOOS=linux GOARCH=arm64 go build -ldflags="-w -s" -o tailscaled ./cmd/tailscaled
GOOS=linux GOARCH=arm64 go build -ldflags="-w -s" -o tailscale ./cmd/tailscale
upx tailscaled tailscale
cd .. 
```
### 4. Dockerfile for Container Image
Create a Dockerfile in your repository root with the following content:
```sh 
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
```
### 5. Build the Docker Image (ARM64)
```sh
docker buildx build --platform linux/arm64 -t tailscale-mikrotik:aarch64 .
```
### 6. Export Image as tar for MikroTik
```sh
docker save -o tailscale-mikrotik-aarch64.tar tailscale-mikrotik:aarch64
```
### 7. (Optional) Test the Image Locally
```sh
docker run --rm --platform=linux/arm64 -it tailscale-mikrotik:aarch64 tailscaled --help
```

   You now have a minimal, ready-to-use Tailscale container image (tailscale-mikrotik-aarch64.tar) that you can upload and deploy on your MikroTik device.