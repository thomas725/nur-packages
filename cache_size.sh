#!/usr/bin/env bash
export NIXPKGS_ALLOW_UNFREE=1
set -euo pipefail

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

# URL of your cache
CACHIX_URL="https://thomas725.cachix.org"

for attr in "${attrs[@]}"; do
  echo "=== $attr ==="

  # Instantiate derivation (errors visible)
  drv=$(nix-instantiate default.nix -A "$attr")

  # Derive the expected output path(s) without realising
  # This gives us the store path(s) without building.
  out_paths=$(nix-store --query --outputs "$drv")

  # For each output path, check if it is already present locally;
  # if not, try to fetch it *only* from Cachix, no building.
  for out in $out_paths; do
    if [ -d "$out" ]; then
      echo "  already present locally: $out"
    else
      echo "  trying to fetch from cache: $out"

      # Use a restricted Nix config via env vars so it:
      # - prefers only your cache and the main nixos cache
      # - does not have a writable store to build into
      # This is a heuristic: if it can't get it from Cachix, we treat it as "not cached".
      NIX_CONFIG="substituters = https://cache.nixos.org/ $CACHIX_URL
trusted-public-keys = cache.nixos.org-1:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa= thomas725.cachix.org-1:u/kJNXSESI2VZU+U9wt0bBXE9K/0dTmvEYi+pWKAXcc=
builders = " nix-store -r "$out" 2>&1 | sed 's/^warning: you did not specify.*//'

      if [ ! -d "$out" ]; then
        echo "  ERROR: $attr output $out is not available from cache (and we refused to build)."
        echo "  -> This likely means CI never pushed this one, or it's a different nixpkgs/NUR revision."
        exit 1
      fi
    fi

    # Now we know $out exists locally (either from before or fetched from cache).
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