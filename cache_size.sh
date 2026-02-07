export NIXPKGS_ALLOW_UNFREE=1
#!/usr/bin/env bash
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

for attr in "${attrs[@]}"; do
  echo "=== $attr ==="

  # Instantiate derivation (suppress warnings)
  drv=$(nix-instantiate default.nix -A "$attr" 2>/dev/null || true)
  if [ -z "${drv:-}" ]; then
    echo "  (could not instantiate)"
    echo
    continue
  fi

  # Realise (build or fetch), suppress stderr (warnings, build logs)
  path=$(nix-store -r "$drv" 2>/dev/null || true)
  if [ -z "${path:-}" ]; then
    echo "  (no path realised)"
    echo
    continue
  fi

  # Get size info; suppress stderr and pick only the store line
  info=$(nix path-info -S "$path" 2>/dev/null | grep '^/nix/store/' || true)
  if [ -z "$info" ]; then
    echo "  (could not get size)"
    echo
    continue
  fi

  # Take the last field as bytes (works for both "two-field" and "four-field" formats)
  bytes=$(echo "$info" | awk '{print $NF}')

  if ! [[ "$bytes" =~ ^[0-9]+$ ]]; then
    echo "  (size not numeric: '$bytes')"
    echo
    continue
  fi

  # Requires bc: nix-env -iA nixpkgs.bc
  mb=$(echo "scale=1; $bytes / 1024 / 1024" | bc)

  echo "  path:  $path"
  echo "  bytes: $bytes"
  echo "  size:  ${mb} MB"
  echo
done
