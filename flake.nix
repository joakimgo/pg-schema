{
  description = "pg-schema";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "01c02c84d3f1536c695a2ec3ddb66b8a21be152b";
      flake = false;
    };
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              haskellPackages = prev.haskell.packages.ghc924.override {
                overrides = nself: nsuper:
                {
                  th-desugar = nsuper.callHackage "th-desugar" "1.13" {};
                  singletons = nsuper.callHackage "singletons" "3.0.1" {};
                  singletons-base = nsuper.callHackage "singletons-base" "3.1" {};
                  singletons-th = nsuper.callHackage "singletons-th" "3.1" {};
                };
              };
            }
            )
          ];
        };

        haskellPackages = pkgs.haskellPackages;

        packageName = "pg-schema";
      in {
        packages.${packageName} = haskellPackages.callCabal2nix packageName ./pg-schema {};

        defaultPackage = self.packages.${system}.${packageName};

        devShell =
          with pkgs.lib;
          let
            ghcWithPkg =
              head (
                splitString "bin" (
                  self.packages.${system}.${packageName}.env.NIX_GHC));
          in pkgs.mkShell {
            buildInputs = with haskellPackages; [ cabal-install ];
            shellHook = ''export PATH=$PATH:${ghcWithPkg}/bin'';
          };
      });
}
