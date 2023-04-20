{
  description = "Slint VS Code plufin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem flake-utils.lib.allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rustPlatform = pkgs.rustPlatform;

        # fonts = pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; };

        version = "1.0.0";

        src = pkgs.fetchFromGitHub {
          owner = "slint-ui";
          repo = "slint";
          rev = "v${version}";
          hash = "sha256-AldOigd8WtCxGP4nuI7NQb/c5X/a8o+OiRGC+CBepOM=";
        };

        lsp = rustPlatform.buildRustPackage rec {
          inherit version src;
          pname = "slint-lsp";

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

          doCheck = false;
          # FONTCONFIG_FILE = fonts;
        };

        nodeDependencies =
          (pkgs.callPackage ./default.nix { }).nodeDependencies;

        plugin = pkgs.stdenv.mkDerivation {
          pname = "slint-vscode";
          inherit version src;
          buildInputs = [ pkgs.nodejs ];
          buildPhase = ''
            ln -s ${nodeDependencies}/lib/node_modules ./node_modules
            export PATH="${nodeDependencies}/bin:$PATH"

            mkdir -p target/debug
            cp ${lsp}/bin/slint-lsp target/debug/slint-lsp
            npm -C editors/vscode run local-package
          '';
          installPhase = ''
            mkdir -p $out
            cp editors/vscode/*.vsix $out
          '';
        };

      in { packages = { inherit lsp plugin; }; });
}
