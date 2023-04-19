{
  description = "Slint VS Code plufin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem flake-utils.lib.allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rustPlatform = pkgs.rustPlatform;

        lsp = rustPlatform.buildRustPackage rec {
          pname = "vscode-slint";
          version = "1.0.0";

          src = pkgs.fetchFromGitHub {
            owner = "slint-ui";
            repo = "slint";
            rev = "v${version}";
            hash = "sha256-AldOigd8WtCxGP4nuI7NQb/c5X/a8o+OiRGC+CBepOM=";
          };

          cargoLock = {
            lockFile = "${src}/Cargo.lock";
            outputHashes = {
              "ft5336-0.1.0" =
                "sha256-XLRhbkVnZrPGeO86nA4rUttKRfu/zWzjL7hDG53Lraw=";
            };
          };
          cargoBuildFlags = "--bin slint-lsp";
          nativeBuildInputs = with pkgs; [
            pkg-config
            fontconfig
            qt6.wrapQtAppsHook
          ];
          buildInputs = with pkgs; [
            fontconfig
            libGL
            xorg.libxcb
            xorg.libX11
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXi
            libxkbcommon
            wayland
            qt6.qtbase.dev
          ];
          buildNoDefaultFeatures = true;
        };

      in { packages = { inherit lsp; }; });
}
