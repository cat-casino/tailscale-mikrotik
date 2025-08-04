#!/usr/bin/env sh
# Copyright (c) 2024 Fluent Networks Pty Ltd & AUTHORS All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
#
# Builds Tailscale for Linux/ARM64 locally on macOS, packs the minimal container image,
# and emits a tarball for MikroTik consumption.
#
# Usage:
#   ./build.sh                # default PLATFORM=linux/arm64, TAILSCALE_VERSION=1.86.2, VERSION=0.1.35
#   PLATFORM=linux/arm64 ./build.sh
#   TAILSCALE_VERSION=1.78.1 VERSION=0.1.36 ./build.sh
#
set -eu

# --- configurable ---
: "${PLATFORM:=linux/arm64}"                    # target container platform
: "${TAILSCALE_VERSION:=1.86.2}"                # upstream Tailscale tag/version
: "${VERSION:=0.1.35}"                          # our container image version/tag
IMAGE="ghcr.io/fluent-networks/tailscale-mikrotik:${VERSION}"
OUT_TAR="tailscale.tar"

# --- cleanup previous artifact ---
rm -f "$OUT_TAR"

# --- ensure tailscale source is present ---
if [ ! -d ./tailscale/.git ]; then
    git -c advice.detachedHead=false clone "https://github.com/tailscale/tailscale.git" --branch "v${TAILSCALE_VERSION}"
fi

# --- derive version metadata ---
cd tailscale
# get commit hash and construct longs
GIT_HASH=$(git rev-parse --short=12 HEAD)
VERSION_SHORT="${TAILSCALE_VERSION}"
VERSION_LONG="${VERSION_SHORT}-${GIT_HASH}"
cd ..

echo "Building Tailscale binaries:"
echo "  TAILSCALE_VERSION=${TAILSCALE_VERSION}"
echo "  VERSION_LONG=${VERSION_LONG}"
echo "  VERSION_SHORT=${VERSION_SHORT}"
echo "  GIT_HASH=${GIT_HASH}"
echo "  PLATFORM=${PLATFORM}"
echo "  Container tag: ${IMAGE}"

# --- build tailscale/tailscaled for linux/arm64 ---
cd tailscale

# Ensure Go is available
if ! command -v go >/dev/null 2>&1; then
    echo "ERROR: go not found in PATH; install Go first." >&2
    exit 1
fi

# Build with explicit target (ARM64 Linux)
echo "Compiling tailscale and tailscaled for linux/arm64..."
# embed version info similar to upstream expectations
LDFLAGS="-w -s -X tailscale.com/version.Long=${VERSION_LONG} -X tailscale.com/version.Short=${VERSION_SHORT} -X tailscale.com/version.GitCommit=${GIT_HASH}"
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o tailscaled ./cmd/tailscaled
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="${LDFLAGS}" -o tailscale ./cmd/tailscale

# Optional compression if upx exists
#if command -v upx >/dev/null 2>&1; then
#    echo "Compressing binaries with upx..."
#    upx tailscaled tailscale
#else
#    echo "upx not found; skipping binary compression"
#fi
cd ..

# --- ensure buildx builder bootstrapped ---
echo "Bootstrapping buildx builder (if needed)..."
docker buildx inspect --bootstrap >/dev/null 2>&1 || true

# --- build container image ---
echo "Building container image ${IMAGE} ..."
docker buildx build \
  --no-cache \
  --build-arg TAILSCALE_VERSION="${TAILSCALE_VERSION}" \
  --build-arg VERSION_LONG="${VERSION_LONG}" \
  --build-arg VERSION_SHORT="${VERSION_SHORT}" \
  --build-arg VERSION_GIT_HASH="${GIT_HASH}" \
  --platform "${PLATFORM}" \
  --load \
  -t "${IMAGE}" .

# --- save tarball ---
echo "Saving image to ${OUT_TAR} ..."
docker save -o "${OUT_TAR}" "${IMAGE}"

echo "Done. Produced ${OUT_TAR} (image: ${IMAGE})"
