{
  description = "Multiple Emacs versions with dependencies.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-22.11";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = inputs:
    with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ emacs-overlay.overlay ];
        };

        # let's have a development shell per Emacs!
        devShells = pkgs.lib.genAttrs emacsPackages (emacsPkg:
          pkgs.mkShell {
            packages = [

              # add extra pkgs to each shell
              # pkgs.hello

              # if you included extra inputs, such as yakspkgs, you can also includ them.
              # yakgspkgs.packages.${system}.vterm

              # https://github.com/nix-community/emacs-overlay
              # The emacs overlay provides up-to-date snapshots of Melpa packages.
              # These will be pure & pinned, so you need to update the flake lock
              # or use appropriate options.
              ((pkgs.emacsPackagesFor pkgs.${emacsPkg}).emacsWithPackages
                (epkgs:
                  [
                    # List test and bootstrap dependencies here:
                    # epkgs.melpaStablePackages.dash
                    # epkgs.elpaPackages.dash
                    # epkgs.dash
                  ]))
            ];
          });

      in rec { # The output set
        # Augment the devShells with a default so that `nix develop` knows what
        # to do.  Run `nix flake show` to see the results.  Per-system,
        # per-Emacs, we have a development environment avaialble.
        devShells = devShells // { default = devShells.emacsNativeComp; };
      });
}
