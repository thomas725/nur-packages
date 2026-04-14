{ lib
, stdenv
, fetchurl
, appimageTools
, electron
, makeWrapper
, wrapGAppsHook3
}:

let
  version = "1.3.0-beta.1";
  releaseTag = "v.1.3.0-Beta.01";
  appImage = fetchurl {
    url = "https://github.com/simongettkandt/claude-ai-desktop-app/releases/download/${releaseTag}/Claude-Desktop-${version}.AppImage";
    hash = "sha256-EauLt8SSPCwuZPmNlz7XknCMjlZ3CLGNwJc+vG05lHU=";
  };
  appimageContents = appimageTools.extractType2 {
    pname = "claude-desktop";
    inherit version;
    src = appImage;
  };
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src = appImage;
  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    electron
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/applications"

    # Extract and copy the app contents
    cp -r ${appimageContents}/* "$out/" || true

    # Find the main executable
    if [ -f "$out/claude-desktop" ]; then
      makeWrapper "$out/claude-desktop" "$out/bin/claude-desktop"
    elif [ -f "$out/AppRun" ]; then
      makeWrapper "$out/AppRun" "$out/bin/claude-desktop"
    fi

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
