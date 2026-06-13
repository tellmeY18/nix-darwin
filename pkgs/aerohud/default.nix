{ lib, stdenv, swift, fetchFromGitHub, aerospace }:

stdenv.mkDerivation {
  pname = "aerohud";
  version = "0-unstable-2024-06-12";

  src = fetchFromGitHub {
    owner = "tellmeY18";
    repo = "aerohud";
    rev = "8d08237560598c66bfeb3c557ae01188b17e7dc6";
    hash = "sha256-pdg8PzQKg1j8+o2j3ZBS56XovWAQVncZ5TU95UymCJk=";
  };

  nativeBuildInputs = [ swift ];

  buildInputs = [ aerospace ];

  buildPhase = ''
    substituteInPlace Sources/AeroSpaceService.swift \
      --replace-fail '/opt/homebrew/bin/aerospace' '${aerospace}/bin/aerospace'
    swiftc -O -o aerohud Sources/*.swift
  '';

  installPhase = ''
    install -Dm755 aerohud $out/bin/aerohud
  '';

  meta = with lib; {
    description = "Native macOS SwiftUI grid overview for AeroSpace";
    homepage = "https://github.com/tellmeY18/aerohud";
    license = licenses.mit;
    platforms = platforms.darwin;
    maintainers = [ ];
  };
}
