#!/usr/bin/env sh
set -eu

# --- configurable defaults ---
: "${PLATFORM:=linux/arm/v7}"
: "${TAILSCALE_VERSION:=1.86.2}"
: "${VERSION:=0.1.35}"
DOCKER_REPO="psleo/tailscale-mikrotik"
IMAGE_TAG="armv7-with-3proxy"
IMAGE="${DOCKER_REPO}:${IMAGE_TAG}"
OUT_TAR="tailscale-mikrotik-${IMAGE_TAG}.tar"

# cleanup
rm -f "${OUT_TAR}"

# ensure sources
[ -d ./tailscale/.git ] || { echo "tailscale/ not found"; exit 1; }
[ -d ./3proxy/.git ]  || { echo "3proxy/ not found";  exit 1; }

# version metadata
cd tailscale
GIT_HASH=$(git rev-parse --short=12 HEAD)
VERSION_SHORT="${TAILSCALE_VERSION}"
VERSION_LONG="${VERSION_SHORT}-${GIT_HASH}"
cd ..

echo "Building local ARMv7 binaries:"
echo "  tailscale v${VERSION_LONG}"

# 1) Build Tailscale locally
cd tailscale
LDFLAGS="-w -s \
  -X tailscale.com/version.Long=${VERSION_LONG} \
  -X tailscale.com/version.Short=${VERSION_SHORT} \
  -X tailscale.com/version.GitCommit=${GIT_HASH}"
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o ../tailscale-armv7 ./cmd/tailscale
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o ../tailscaled-armv7 ./cmd/tailscaled
cd ..

# optional UPX
#if command -v upx >/dev/null 2>&1; then
#  upx --best --lzma tailscaled-armv7 tailscale-armv7
#fi

# 2) Build 3proxy locally via Docker (ARMv7)
/bin/echo "Building 3proxy in Docker for ARMv7..."
docker run --rm \
  --platform linux/arm/v7 \
  -v "$PWD/3proxy":/src \
  -w /src \
  alpine:3.19 \
  sh -euxc "apk add --no-cache build-base openssl-dev zlib-dev linux-headers make && make -f Makefile.Linux all"
cp 3proxy/bin/3proxy 3proxy-armv7

# 3) Prepare build context files (they're already in root with correct names)

# 4) Bootstrap buildx
docker buildx inspect --bootstrap >/dev/null 2>&1 || true

# 5) Build Docker image
docker buildx build \
  --platform "${PLATFORM}" \
  -f Dockerfile.armv7 \
  -t "${IMAGE}" \
  --load \
  .

# 6) Save tarball
echo "Saving ${IMAGE} to ${OUT_TAR}..."
docker save -o "${OUT_TAR}" "${IMAGE}"

echo "Done. Built ${IMAGE}"
