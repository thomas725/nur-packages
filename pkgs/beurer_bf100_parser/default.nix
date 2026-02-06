{ lib
, rustPlatform
, fetchFromGitLab
}:

let
  rev = "d5b4eeba628730008b9e6f9f111eb26a4d767020";
in
rustPlatform.buildRustPackage rec {
  pname = "beurer_bf100_parser";
  version = "git-${builtins.substring 0 7 rev}";

  src = fetchFromGitLab {
    owner = "thomas351";
    repo  = "beurer_bf100_parser";
    inherit rev;
    hash = "sha256-G1XW8JJSXQwvVYFfQyyssXsA7UCj4yygH1L8cT1d6a8=";
    domain = "gitlab.com";
  };

  # If your project has a Cargo.lock, this is usually enough:
  cargoLock = {
    lockFile = src + "/Cargo.lock";
  };

  # If you need extra native build inputs (for example, OpenSSL):
  # nativeBuildInputs = [ pkg-config ];
  # buildInputs = [ openssl ];

  meta = with lib; {
    description = "Parser for Beurer BF100 scale data";
    homepage    = "https://gitlab.com/thomas351/beurer_bf100_parser";
    license     = licenses.agpl3Only;
    platforms   = platforms.unix;
  };
}