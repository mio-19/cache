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
    chaotic.url = "git+https://github.com/lonerOrz/nyx-loner.git";
    # bad for cache:
    chaotic.inputs.nixpkgs.follows = "nixpkgs";
    chaotic.inputs.jovian.follows = "jovian";
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
    #emacs-overlay = {
    #  url = "github:nix-community/emacs-overlay";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    #};
    razerdaemon = {
      #url = "github:JosuGZ/razer-laptop-control";
      #url = "git+https://github.com/JosuGZ/razer-laptop-control.git";
      url = "git+https://github.com/mio-19/razer-laptop-control.git";
      inputs.nixpkgs.follows = "nixpkgs";
      #inputs.flake-utils.follows = "flake-utils";
    };
    stable-diffusion-webui-nix = {
      url = "github:Janrupf/stable-diffusion-webui-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixified-ai = {
      url = "github:nixified-ai/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chester = {
      url = "git+https://codeberg.org/chester-lang/chester.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.flake-parts.follows = "nur/flake-parts";
    };
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      #inputs.home-manager.follows = "home-manager";
      inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
      #inputs.flake-utils.follows = "flake-utils";
      inputs.nix-steipete-tools.inputs.nixpkgs.follows = "nixpkgs";
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
                    #inputs.emacs-overlay.overlays.package
                    inputs.nix-openclaw.overlays.default
                  ]
                else
                  [
                    inputs.darwin-emacs.overlays.default
                    inputs.chaotic.overlays.default
                    #inputs.emacs-overlay.overlays.package
                    inputs.nix-openclaw.overlays.default
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
            pkgs-cuda = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              config.cudaSupport = true;
              overlays = ([
                inputs.chaotic.overlays.default
              ]);
            };
            lib = inputs.nixpkgs.lib;
            epkgs = pkgs.emacsPackagesFor pkgs.emacs-30;
          in
          {
            packages = lib.mkMerge [
              (lib.mkIf pkgs.stdenv.isDarwin {
                inherit (pkgs)
                  lix
                  ;
              })
              (lib.mkIf (pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isAarch64) {
                inherit (pkgs)
                  #zed-editor
                  #emacs-unstable
                  emacs-30
                  element-desktop
                  remmina
                  sbcl
                  octaveFull
                  ;
                emacs-with-pack = epkgs.emacsWithPackages [
                  epkgs.nix-mode
                  epkgs.magit
                  epkgs.agda2-mode
                ];
                #lix_stable = pkgs.lixPackageSets.stable.lix;
              })
              {
                universal = (
                  pkgs.symlinkJoin {
                    name = "universal";

                    paths = with pkgs; [
                      openclaw
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
                      #zed-editor # takes maybe more than 6h
                      qbittorrent-enhanced
                      moonlight-qt
                      uv
                      nodejs
                      nodejs_latest
                      p7zip-rar
                      fresh-editor
                    ];
                  }
                );
                chester = (inputs.chester.packages."${pkgs.stdenv.hostPlatform.system}".default);
                inherit (pkgs.emacs.pkgs) magit nix-mode agda2-mode;
              }
              (lib.mkIf (pkgs.stdenv.isLinux) {
                inherit (pkgs)
                  totem
                  gnome-session
                  gamescope
                  obsidian
                  gnome-calendar
                  aseprite
                  wiliwili
                  #freecad
                  plezy
                  ;
                inherit (pkgs.kdePackages)
                  kwin
                  kdeplasma-addons
                  gwenview
                  fcitx5-with-addons
                  plasma-workspace
                  ;
              })
              (lib.mkIf (system == "x86_64-linux") {
                wine64_package = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg;
                #comfyuinvidia = inputs.nixified-ai.packages."${pkgs.stdenv.hostPlatform.system}".comfyui-nvidia;
                /*
                  # build failed
                  v3ssss = (
                    pkgs.symlinkJoin {
                      name = "v3ssss";

                      paths = with pkgs.pkgsx86_64_v3; [
                        nix
                        systemd
                        tmux
                        nano
                        bluez
                        dbus
                        networkmanager
                        polkit
                        power-profiles-daemon
                        openssh
                        plymouth
                        iwd
                      ];
                    }
                  );
                */
                v3sssscuda = (
                  pkgs.symlinkJoin {
                    name = "v3sssscuda";

                    paths = with pkgs-cuda.pkgsx86_64_v3; [
                      nix
                      systemd
                      tmux
                      nano
                      dbus
                      bluez
                      networkmanager
                      polkit
                      power-profiles-daemon
                      openssh
                      plymouth
                      iwd
                    ];
                  }
                );
                razer-laptop-control = inputs.razerdaemon.packages.x86_64-linux.default;
                inherit
                  (
                    pkgs # .jovian-chaotic
                  )
                  mesa-radeonsi-jupiter
                  mesa-radv-jupiter
                  mesa
                  inputplumber
                  wireplumber
                  ; # gamescope-session; # steamos-manager;
                i686s = (
                  pkgs.symlinkJoin {
                    name = "i686s";

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
                packagesssscuda = (
                  pkgs.symlinkJoin {
                    name = "packagesssscuda";

                    paths = with pkgs-cuda; [
                      davinci-resolve
                      retroarch-full
                      krita
                      nix
                      nixd
                      pixelorama
                      zeroad
                      #vdrift
                      opencv
                      #freecad
                    ];
                  }
                );
                packagessss = (
                  pkgs.symlinkJoin {
                    name = "packagessss";

                    paths = with pkgs; [
                      gitbutler
                      #davinci-resolve
                      steam
                      lutris
                      prusa-slicer
                      android-studio
                      ryubing
                      openrazer-daemon
                      gamescope_git
                      ollama-cuda
                      android-translation-layer
                      retroarch-full
                      wineWowPackages.waylandFull
                      krita
                      pixelorama
                      flightgear
                    ];
                  }
                );
                kernel2 = (
                  pkgs.symlinkJoin {
                    name = "kernel2-linux-kernel-modules";

                    paths =
                      with pkgs;
                      let
                        linuxv3gcc = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V3"; });
                        linuxv4gcc = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V4"; });
                        linuxzen4gcc = (pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "ZEN4"; });
                        linuxv3 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V3"; });
                        linuxv4 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V4"; });
                        linuxzen4 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "ZEN4"; });
                      in
                      [
                        linuxv3gcc.kernel
                        /*
                          linuxv3gcc.zfs_cachyos
                          linuxv3gcc.xone
                          linuxv3gcc.vmware
                          linuxv3gcc.nvidiaPackages.stable.open
                        */
                        #linuxv3.kernel
                      ];
                  }
                );
                #linuxv3_kernel = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V3"; }).kernel;
                kerneljovian = (
                  pkgs.symlinkJoin {
                    name = "default-linux-kernel-modules";

                    paths = with pkgs; [
                      linuxPackages_jovian.kernel
                      linuxPackages_jovian.${pkgs.zfs.kernelModuleAttribute}
                    ];
                  }
                );
                kernelzen4lts = (
                  pkgs.symlinkJoin {
                    name = "default-linux-kernel-modules-zen4lts";

                    paths =
                      with pkgs;
                      let
                        linuxzen4lts = (pkgs.linuxPackages_cachyos-lts.cachyOverride { mArch = "ZEN4"; });
                      in
                      [
                        linuxzen4lts.kernel
                        linuxzen4lts.zfs_cachyos
                        linuxzen4lts.nvidiaPackages.stable.open
                      ];
                  }
                );
                /*
                  kernel1 = (
                    pkgs.symlinkJoin {
                      name = "default-linux-kernel-modules";

                      paths =
                        with pkgs;
                        let
                          linuxzen4 = (pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "ZEN4"; });
                        in
                        [
                          linuxzen4.kernel
                          linuxzen4.zfs_cachyos
                          linuxzen4.nvidiaPackages.stable.open
                        ];
                    }
                  );
                */
              })
            ];
          };
      }
    );
}
