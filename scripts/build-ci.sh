#!/usr/bin/env bash
# Build script for Cloudflare Workers Builds.
# Workers Builds runs Linux x86_64 with no Zola preinstalled.
set -euo pipefail

ZOLA_VERSION="0.22.1"
ZOLA_TARBALL="zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
ZOLA_URL="https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/${ZOLA_TARBALL}"

# git submodule update --init --recursive

if ! [ -x ./zola ]; then
  curl -sSL "$ZOLA_URL" | tar xz
fi

./zola build
