{
  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nixpkgs-staging.url = "github:NixOS/nixpkgs/staging";
    darwin-emacs = {
      url = "github:nix-giant/nix-darwin-emacs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "git+https://github.com/chaotic-cx/nyx.git?ref=nyxpkgs-unstable";
    #jovian.follows = "chaotic/jovian";
    jovian = {
      url = "git+https://github.com/Jovian-Experiments/Jovian-NixOS.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    razerdaemon = {
      #url = "github:JosuGZ/razer-laptop-control";
      url = "git+https://github.com/JosuGZ/razer-laptop-control.git";
      inputs.nixpkgs.follows = "nixpkgs";
      #inputs.flake-utils.follows = "flake-utils";
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
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = (
                if (lib.hasSuffix "-linux" system) then
                  [
                    inputs.jovian.overlays.default
                    inputs.chaotic.overlays.default
                    inputs.emacs-overlay.overlays.package
                  ]
                else
                  [
                    inputs.darwin-emacs.overlays.default
                    inputs.chaotic.overlays.default
                    inputs.emacs-overlay.overlays.package
                  ]
              );
              config.permittedInsecurePackages = [
                "qtwebengine-5.15.19"
                "electron-36.9.5" # for joplin-desktop
                "jitsi-meet-1.0.8792" # for element-desktop - see https://github.com/NixOS/nixpkgs/pull/426541
              ];
            };
            pkgs' = import inputs.nixpkgs-staging {
              inherit system;
              config.allowUnfree = true;
              config.permittedInsecurePackages = [
                "qtwebengine-5.15.19"
                "electron-36.9.5" # for joplin-desktop
                "jitsi-meet-1.0.8792" # for element-desktop - see https://github.com/NixOS/nixpkgs/pull/426541
              ];
            };
            lib = inputs.nixpkgs.lib;
            epkgs = pkgs.emacsPackagesFor pkgs.emacs-30;
          in
          {
            packages = lib.mkMerge [
              (lib.mkIf (pkgs.stdenv.isDarwin) {
                inherit (pkgs)
                  #emacs-unstable
                  emacs-30
                  firefox_nightly
                  element-desktop
                  remmina
                  librewolf
                  thunderbird-esr
                  sbcl
                  octaveFull
                  ;
                emacs-with-pack = epkgs.emacsWithPackages [
                  epkgs.nix-mode
                  epkgs.magit
                  epkgs.agda2-mode
                ];
              })
              {
                universal = (
                  pkgs.symlinkJoin {
                    name = "universal";
                    # cache dependencies for those packages:
                    paths = with pkgs; [
                      musescore
                      audacity
                      inkscape
                      noto-fonts-color-emoji
                      joplin-desktop
                      famistudio
                      starship
                      nix
                      lean4
                      tailscale
                      trayscale
                      zed-editor
                      qbittorrent-enhanced
                      moonlight-qt
                    ];
                  }
                );
                #inherit (pkgs) thunderbird-esr; # jellyfin-media-player
                inherit (pkgs.emacs.pkgs) magit nix-mode agda2-mode;
              }
              (lib.mkIf (pkgs.stdenv.isLinux) {
                inherit (pkgs)
                  totem
                  gnome-session
                  obsidian
                  gamescope
                  gnome-calendar
                  chromium
                  aseprite
                  wiliwili
                  ;
                inherit (pkgs.kdePackages)
                  kwin
                  kdeplasma-addons
                  gwenview
                  fcitx5-with-addons
                  ;
              })
              (lib.mkIf (system == "x86_64-linux") {
                razer-laptop-control = inputs.razerdaemon.packages.x86_64-linux.default;
                inherit (pkgs.jovian-chaotic) mesa-radeonsi-jupiter mesa-radv-jupiter; # gamescope-session; # steamos-manager;
                i686s = (
                  pkgs.symlinkJoin {
                    name = "i686s";
                    # cache dependencies for those packages:
                    paths = with pkgs.pkgsi686Linux; [
                      mesa-radeonsi-jupiter
                      mesa-radv-jupiter
                      gamescope-wsi
                      kdePackages.qtwayland
                      mesa
                      curl
                      mangohud
                    ];
                  }
                );
                wine = pkgs.wineWowPackages.waylandFull;
                inherit (pkgs)
                  davinci-resolve
                  steam
                  lutris
                  prusa-slicer
                  android-studio
                  ryubing
                  #gg
                  ;
                default = (
                  pkgs.symlinkJoin {
                    name = "default-linux-kernel-modules";
                    # cache dependencies for those packages:
                    paths =
                      with pkgs;
                      let
                        linuxv3gcc = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V3"; });
                        linuxv4gcc = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V4"; });
                        linuxv3 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V3"; });
                        linuxv4 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V4"; });
                      in
                      [
                        linuxv3gcc.kernel
                        linuxv4gcc.kernel
                        linuxv3.kernel
                        linuxv4.kernel
                        linuxv3gcc.zfs_cachyos
                        linuxv3gcc.xone
                        linuxv3gcc.vmware
                        linuxv3gcc.nvidiaPackages.stable
                        linuxv4gcc.zfs_cachyos
                        linuxv4gcc.xone
                        linuxv4gcc.vmware
                        linuxv4gcc.nvidiaPackages.stable
                        linuxPackages_jovian.kernel
                        linuxPackages_jovian.${pkgs.zfs.kernelModuleAttribute}
                      ];
                  }
                );
              })
            ];
          };
      }
    );
}
