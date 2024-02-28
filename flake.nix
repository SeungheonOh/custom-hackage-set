{
  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://foliage.cachix.org"
    ];
    extra-trusted-substituters = [
      # If you have a nixbuild.net SSH key set up, you can pull builds from there
      # by using '--extra-substituters ssh://eu.nixbuild.net' manually, otherwise this
      # does nothing
      "ssh://eu.nixbuild.net"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "foliage.cachix.org-1:kAFyYLnk8JcRURWReWZCatM9v3Rk24F5wNMpEj14Q/g="
      "nixbuild.net/smart.contracts@iohk.io-1:s2PhQXWwsZo1y5IxFcx2D/i2yfvgtEnRBOZavlA8Bog="
    ];
    allow-import-from-derivation = true;
  };
  description = "Metadata for Cardano's Haskell package repository";

  inputs = {
    nixpkgs.follows = "haskell-nix/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";

    foliage = {
      url = "github:input-output-hk/foliage";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.haskell-nix.follows = "haskell-nix";
      inputs.hackage-nix.follows = "hackage-nix";
    };

    hackage-nix = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };

    haskell-nix.url = "github:input-output-hk/haskell.nix";
    iohk-nix.url = "github:input-output-hk/iohk-nix";
    iohk-nix.inputs.nixpkgs.follows = "haskell-nix/nixpkgs";
  };

  outputs = inputs@{ flake-parts, nixpkgs, haskell-nix, iohk-nix, foliage, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
      ];
      debug = true;
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
#      hercules-ci.github-pages.branch = "master";

      perSystem = { config, system, lib, self', ... }:
        let
          pkgs =
            import haskell-nix.inputs.nixpkgs {
              inherit system;
              overlays = [
                haskell-nix.overlay
                iohk-nix.overlays.crypto
                iohk-nix.overlays.haskell-nix-crypto
              ];
              inherit (haskell-nix) config;
            };
        in {
          devShells.default = with pkgs; mkShellNoCC {
            name = "cardano-haskell-packages";
            buildInputs = [
              bash
              coreutils
              curlMinimal.bin
              gitMinimal
              gnutar
              foliage.packages.${system}.default
            ];
          };
        };
    };
}
