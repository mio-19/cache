# cache
generate nix cache

##  cache

```nix
  nix = {
    settings = {
      substituters = [
        "https://mio-cache.cachix.org/"
      ];
      trusted-public-keys = [
        "mio-cache.cachix.org-1:ouuIJZ59HIflYjpLW6DRyMc1c+6r3kC/LHuqGUsWigg="
      ];
    };
  };
```

```zsh
--option 'extra-substituters' 'https://mio-cache.cachix.org/' --option extra-trusted-public-keys "mio-cache.cachix.org-1:ouuIJZ59HIflYjpLW6DRyMc1c+6r3kC/LHuqGUsWigg="
```

## pastebin

```

    - name: Maximize build space
      if: runner.os == 'Linux'
      uses: mio-19/maximize-build-space@patch-1
      with:
        root-reserve-mb: 512
        swap-size-mb: 42000
        overprovision-lvm: 'true'
        remove-dotnet: 'true'
        remove-android: 'true'
        remove-haskell: 'true'
        remove-codeql: 'true'
        remove-docker-images: 'true'
        build-mount-path: /nix
    - run: sudo sysctl kernel.apparmor_restrict_unprivileged_userns=0
      if: runner.os == 'Linux'
```