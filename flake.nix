{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-staging.url = "github:NixOS/nixpkgs/staging";
    jovian = {
      url = "git+https://github.com/Jovian-Experiments/Jovian-NixOS.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "git+https://github.com/chaotic-cx/nyx.git?ref=nyxpkgs-unstable";
    rosetta-spice.url = "github:zhaofengli/rosetta-spice";
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        config,
        withSystem,
        moduleWithSystem,
        ...
      }:
      {
        imports = [
        ];
        flake = {
        };
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        perSystem =
          {
            system,
            ...
          }:
          let
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.jovian.overlays.default
                inputs.chaotic.overlays.default
              ];
            };
            pkgs' = import inputs.nixpkgs-staging {
              inherit system;
            };
            lib = inputs.nixpkgs.lib;
          in
          {
            packages = liv.mkMerge [
              {
                inherit (pkgs') remmina librewolf thunderbird-esr;
              }
              (lib.mkIf (system == "x86_64-linux") {
                linux_jovian = pkgs.linux_jovian;
                default = (
                  pkgs.stdenv.mkDerivation rec {
                    name = "example-package-${version}";
                    version = "1.0";
                    src = ./.;
                    # cache dependencies for those packages:
                    buildInputs = with pkgs; davinci-resolve.nativeBuildInputs;
                    buildPhase = "echo echo Hello World > example";
                    installPhase = "install -Dm755 example $out";
                  }
                );
              })
            ];
          };
      }
    );
}
