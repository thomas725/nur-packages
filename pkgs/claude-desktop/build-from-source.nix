# Claude Desktop - Built from source using Node.js/Electron
# This avoids EGL compatibility issues with pre-built AppImages
# Source: https://github.com/simongettkandt/claude-ai-desktop-app
# Uses Electron 41.2.1 which is compatible with current Mesa

{ lib
, stdenv
, fetchFromGitHub
, nodejs_22
, makeWrapper
, appimage-run
, appimageTools
, libxkbcommon
, mesa
}:

let
  version = "1.3.0";
  electron_version = "41.2.1";
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src = fetchFromGitHub {
    owner = "simongettkandt";
    repo = "claude-ai-desktop-app";
    rev = "v.${version}";
    hash = "sha256-wCpf6Th6rvE6Ftnn1GL+TE/QeeP3oqbGH7+DRUJeUsA=";
  };

  nativeBuildInputs = [
    nodejs_22
    makeWrapper
  ];

  # Copy node_modules dependencies from npm cache instead of downloading
  # This makes the build more reproducible
  dontUnpack = false;

  # Build phase: install dependencies and build AppImage
  buildPhase = ''
    npm ci --ignore-scripts
    npm run build-appimage -- --publish never
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/applications

    # Find the generated AppImage in dist folder
    APPIMAGE=$(find dist -name "*.AppImage" -type f 2>/dev/null | head -1)

    if [ -z "$APPIMAGE" ]; then
      echo "Error: No AppImage found in dist/ after build"
      ls -la dist/ 2>/dev/null || echo "dist/ doesn't exist"
      exit 1
    fi

    echo "Found AppImage: $APPIMAGE"
    chmod +x "$APPIMAGE"

    # Copy AppImage to output
    cp "$APPIMAGE" $out/claude-desktop.AppImage
    chmod +x $out/claude-desktop.AppImage

    # Create a wrapper script that runs the AppImage
    # Using --no-sandbox because the Chrome SUID sandbox doesn't work in AppImages
    makeWrapper $out/claude-desktop.AppImage $out/bin/claude-desktop \
      --add-flags "--no-sandbox"

    # Create desktop entry
    cat > $out/share/applications/claude-desktop.desktop <<'DESKTOP'
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
DESKTOP

    # Fix the Exec path in desktop entry
    sed -i "s|\$out|$out|g" $out/share/applications/claude-desktop.desktop
  '';

  meta = with lib; {
    description = "Claude AI Desktop Application (built from source with Electron 41)";
    longDescription = ''
      Claude Desktop application built from source to ensure compatibility with
      current Mesa libraries. Uses Electron 41.2.1 which works with modern OpenGL/EGL.
    '';
    homepage = "https://github.com/simongettkandt/claude-ai-desktop-app";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "claude-desktop";
  };
}
