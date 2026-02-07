export NIXPKGS_ALLOW_UNFREE=1
for attr in npupnp libupnpp upplay eezupnp betterbird-bin czkawka-git birt-designer beurer_bf100_parser; do
  echo "=== $attr ==="
  # Instantiate the derivation
  drv=$(nix-instantiate default.nix -A "$attr")
  # Realise it (this will fetch from Cachix or build if not cached)
  path=$(nix-store -r "$drv")
  # Show size of the realised path
  nix path-info -S "$path"
  echo
done
