{
  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    #nixpkgs-staging.url = "github:NixOS/nixpkgs/staging";
    jovian = {
      url = "git+https://github.com/Jovian-Experiments/Jovian-NixOS.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    #nixpkgs-darwin.url = "github:NixOS/nixpkgs/master";
    darwin-emacs = {
      url = "github:nix-giant/nix-darwin-emacs";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
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
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
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
          args@{
            system,
            pkgs,
            ...
          }:
          let
            pkgs =
              if (args.pkgs.stdenv.isLinux) then
                import inputs.nixpkgs {
                  inherit system;
                  config.allowUnfree = true;
                  overlays = [
                    inputs.jovian.overlays.default
                    inputs.chaotic.overlays.default
                    inputs.emacs-overlay.overlays.package
                  ];
                }
              else
                import inputs.nixpkgs-darwin {
                  inherit system;
                  config.allowUnfree = true;
                  overlays = [
                    inputs.darwin-emacs.overlays.default
                    inputs.chaotic.overlays.default
                    inputs.emacs-overlay.overlays.package
                  ];
                };
            pkgs' = import inputs.nixpkgs-staging {
              inherit system;
              config.allowUnfree = true;
            };
            lib = inputs.nixpkgs.lib;
            epkgs = pkgs.emacsPackagesFor pkgs.emacs-unstable;
          in
          {
            packages = lib.mkMerge [
              (lib.mkIf (pkgs.stdenv.isDarwin) {
                inherit (pkgs) emacs-unstable emacs-30;
                emacs-with-pack = epkgs.emacsWithPackages [
                  epkgs.nix-mode
                  epkgs.magit
                  epkgs.agda2-mode
                ];
                /*
                  inherit (pkgs')
                  remmina
                  librewolf
                  thunderbird-esr
                  telegram-desktop
                  materialgram
                  ;
                */
              })
              {
                inherit (pkgs) musescore prusa-slicer audacity inkscape;
                #inherit (pkgs) sbcl;
                inherit (pkgs.emacs.pkgs) magit nix-mode agda2-mode;
              }
              (lib.mkIf (pkgs.stdenv.isLinux) {
                inherit (pkgs) totem gnome-session obsidian;
              })
              (lib.mkIf (system == "x86_64-linux") {
                inherit (pkgs) davinci-resolve steam;
                linuxv3gcc = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V3"; }).kernel;
                #linuxv4gcc = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V4"; }).kernel;
                linuxv3 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V3"; }).kernel;
                #linuxv4 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V4"; }).kernel;
                linuxv3gcczfscachyos = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V3"; }).zfs_cachyos;
                #linux_jovian = pkgs.linux_jovian;
                /*
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
                */
              })
            ];
          };
      }
    );
}
