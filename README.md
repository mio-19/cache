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
nixPath