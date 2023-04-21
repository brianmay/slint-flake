{
  description = "Slint VS Code plufin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
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
        };

        nodeDependencies =
          (pkgs.callPackage ./default.nix { }).nodeDependencies;

        wasmPkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        wasmRustPlatform = wasmPkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

        /* plugin_old = pkgs.stdenv.mkDerivation {
             pname = "slint-vscode";
             inherit version src;
             nativeBuildInputs = [ wasmRustPlatform ];
             buildInputs = with pkgs; [ nodejs wasm-pack ];
             buildPhase = ''
               ln -s ${nodeDependencies}/lib/node_modules ./editors/vscode/node_modules
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
        */

        plugin = rustPlatform.buildRustPackage {
          inherit version src;
          pname = "slint-lsp";

          cargoLock = {
            lockFile = "${src}/Cargo.lock";
            outputHashes = {
              "ft5336-0.1.0" =
                "sha256-XLRhbkVnZrPGeO86nA4rUttKRfu/zWzjL7hDG53Lraw=";
            };
          };
          nativeBuildInputs = with pkgs; [
            nodejs
            wasm-pack
            wasm-bindgen-cli
            binaryen
            wasmRustPlatform
          ];
          buildInputs = with pkgs; [ ];
          buildPhase = ''
            set -x
            export HOME=/tmp
            # cargo build --bin slint-lsp --release --target=wasm32-unknown-unknown

            ln -s ${nodeDependencies}/lib/node_modules ./editors/vscode/node_modules
            export PATH="${nodeDependencies}/bin:$PATH"

            mkdir -p target/debug
            cp ${lsp}/bin/slint-lsp target/debug/slint-lsp
            # cd editors/vscode
            # wasm-pack build --target web --out-name index ../../tools/lsp --no-default-features --features preview-lense,preview-api 
            # wasm-pack build --release --target web --out-dir $PWD/out ../../api/wasm-interpreter --features highlight
            # npm run compile
            npm -C editors/vscode run local-package
          '';
          installPhase = ''
            mkdir -p $out
            cp editors/vscode/*.vsix $out
          '';

          doCheck = false;
        };

      in { packages = { inherit lsp plugin; }; });
}
