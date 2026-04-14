{ lib
, stdenv
, fetchurl
, wrapGAppsHook3
}:

let
  version = "1.3.0-beta.1";
  releaseTag = "v.1.3.0-Beta.01";
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src = fetchurl {
    url = "https://github.com/simongettkandt/claude-ai-desktop-app/releases/download/${releaseTag}/Claude-Desktop-${version}.AppImage";
    hash = "sha256-EauLt8SSPCwuZPmNlz7XknCMjlZ3CLGNwJc+vG05lHU=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/applications"

    # Install the AppImage
    cp "$src" "$out/bin/claude-desktop.AppImage"
    chmod +x "$out/bin/claude-desktop.AppImage"

    # Create a launcher script using relative path
    cat > "$out/bin/claude-desktop" <<'LAUNCHER'
#!/bin/sh
exec "$(dirname "$0")/claude-desktop.AppImage" "$@"
LAUNCHER
    chmod +x "$out/bin/claude-desktop"

    # Install desktop file
    cat > "$out/share/applications/claude-desktop.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Desktop
Comment=Claude AI Desktop Application for Linux
Exec=$out/bin/claude-desktop %u
Icon=electron
Terminal=false
Categories=Development;Utility;
Keywords=claude;ai;assistant;
EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude AI Desktop Application for Linux";
    homepage = "https://github.com/simongettkandt/claude-ai-desktop-app";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
