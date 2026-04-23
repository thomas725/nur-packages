# Claude Desktop - Built from source using Node.js/Electron
# This avoids EGL compatibility issues with pre-built AppImages
# Source: https://github.com/simongettkandt/claude-ai-desktop-app

{ lib
, stdenv
, fetchFromGitHub
, nodejs
, npm
, electron
, makeWrapper
}:

let
  version = "1.3.0";
in
stdenv.mkDerivation {
  pname = "claude-desktop-source";
  inherit version;

  src = fetchFromGitHub {
    owner = "simongettkandt";
    repo = "claude-ai-desktop-app";
    rev = "v.${version}";
    hash = "sha256-PLACEHOLDER"; # TODO: Run `nix flake prefetch` to get actual hash
  };

  nativeBuildInputs = [
    nodejs
    npm
    makeWrapper
  ];

  buildInputs = [
    electron
  ];

  # npm install dependencies
  preBuild = ''
    npm install --no-save
  '';

  # Build the AppImage
  buildPhase = ''
    npm run build-appimage
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/applications

    # Find the generated AppImage
    APPIMAGE=$(find . -name "*.AppImage" -type f | head -1)

    if [ -z "$APPIMAGE" ]; then
      echo "Error: No AppImage found after build"
      exit 1
    fi

    # Copy AppImage to output
    cp "$APPIMAGE" $out/claude-desktop.AppImage
    chmod +x $out/claude-desktop.AppImage

    # Create a wrapper script
    makeWrapper $out/claude-desktop.AppImage $out/bin/claude-desktop \
      --add-flags "--no-sandbox"

    # Create desktop entry
    cat > $out/share/applications/claude-desktop.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Desktop
Comment=Claude AI Desktop Application
Exec=$out/bin/claude-desktop %u
Icon=electron
Terminal=false
Categories=Development;Utility;
Keywords=claude;ai;assistant;
EOF
  '';

  meta = with lib; {
    description = "Claude AI Desktop Application (built from source)";
    homepage = "https://github.com/simongettkandt/claude-ai-desktop-app";
    license = licenses.unfree; # Check actual license
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
