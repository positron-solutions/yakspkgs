# Copyright (C) 2022 Positron Solutions

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-22.05";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    emacs-overlay.url = "github:nix-community/emacs-overlay";

    # sources for output packages
    rust-overlay.url = "github:oxalica/rust-overlay";
    emacs-vterm-src = {
      url =
        "github:akermu/emacs-libvterm?rev=3155a477b43c1567d754768f5be79296440ebaf8";
      flake = false;
    };
  };

  outputs = inputs:
    with inputs;

    flake-utils.lib.eachDefaultSystem (system:

      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) emacs-overlya.overlay ];
        };

        emacs-vterm = pkgs.stdenv.mkDerivation {
          name = "emacs-vterm";
          src = emacs-vterm-src;
          nativeBuildInputs = with pkgs; [ cmake ];
          buildInputs = with pkgs; [ glib.out libvterm-neovim ];
          installPhase = ''
            mkdir -p $out
            cp ../vterm-module.so $out
            cp ../vterm.el $out
          '';
        };

        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rustfmt" ];
        };

        # let's have a development shell per Emacs!
        devShells = pkgs.lib.genAttrs emacsPackages (emacsPkg:
          pkgs.mkShell {
            packages = [
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

                    epkgs.melpaPackages.elisp-lint
                  ]))
            ];
          });

      in rec { # The output set
        packages = {
          inherit emacs-vterm rust;
          inherit (pkgs) grep ripgrep git;
        };

        # Augment the devShells with a default so that `nix develop` knows what
        # to do.  Run `nix flake show` to see the results.  Per-system,
        # per-Emacs, we have a development environment avaialble.
        devShells = devShells // { default = devShells.emacsNativeComp; };
      });
}
