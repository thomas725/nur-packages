#!/usr/bin/env bash
set -euo pipefail

# Allow unfree packages during this script
export NIXPKGS_ALLOW_UNFREE=1

attrs=(
  npupnp
  libupnpp
  upplay
  eezupnp
  betterbird-bin
  czkawka-git
  birt-designer
  beurer_bf100_parser
)

CACHIX_URL="https://thomas725.cachix.org"
CACHIX_KEY="thomas725.cachix.org-1:u/kJNXSESI2VZU+U9wt0bBXE9K/0dTmvEYi+pWKAXcc="

for attr in "${attrs[@]}"; do
  echo "=== $attr ==="

  # Instantiate derivation
  drv=$(nix-instantiate default.nix -A "$attr")

  # Expected output paths (without building)
  out_paths=$(nix-store --query --outputs "$drv")

  cached_any=false

  for out in $out_paths; do
    if [ -d "$out" ]; then
      cached_any=true
      echo "  already present locally: $out"
    else
      echo "  trying to fetch from $CACHIX_URL only: $out"

      # Try to realise from your Cachix cache only, with builders disabled.
      # Strip the '--add-root' warning but keep other output (like copying path...).
      NIX_CONFIG="substituters = $CACHIX_URL
trusted-public-keys = $CACHIX_KEY
builders = " \
      nix-store --realise "$out" 2> >(sed '/^warning: you did not specify.*--add-root/d' >&2) || true

      if [ -d "$out" ]; then
        cached_any=true
        echo "  fetched from cache: $out"
      else
        echo "  NOT CACHED: $out"
      fi
    fi
  done

  if [ "$cached_any" = false ]; then
    echo "  -> no outputs present or cached for $attr, skipping size"
    echo
    continue
  fi

  # Size reporting for outputs that exist
  for out in $out_paths; do
    if [ ! -d "$out" ]; then
      continue
    fi

    info=$(nix path-info -S "$out" 2>/dev/null | grep '^/nix/store/' || true)
    if [ -z "$info" ]; then
      echo "  (could not get size for $out)"
      continue
    fi

    bytes=$(echo "$info" | awk '{print $NF}')
    if ! [[ "$bytes" =~ ^[0-9]+$ ]]; then
      echo "  (size not numeric for $out: '$bytes')"
      continue
    fi

    mb=$(echo "scale=1; $bytes / 1024 / 1024" | bc)
    echo "  path:  $out"
    echo "  bytes: $bytes"
    echo "  size:  ${mb} MB"
  done

  echo
done