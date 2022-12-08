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
  description = "3rd party dependencies packaged specifically for development with Emacs.";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-22.11";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # sources for output packages
    rust-overlay.url = "github:oxalica/rust-overlay";
    emacs-vterm-src = {
      url = "github:akermu/emacs-libvterm";
      flake = false;
    };
  };

  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let

        pkgs =  import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        emacs-vterm = pkgs.stdenv.mkDerivation {
          name = "emacs-vterm";
          src = emacs-vterm-src;
          nativeBuildInputs = with pkgs; [ cmake ];
          buildInputs = with pkgs; [ glib.out libvterm-neovim ];
          installPhase = ''
            mkdir -p $out
            cp ../vterm-module.so "''${out}/lib"
          '';
        };

        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rustfmt" ];
        };

      in rec { # The output set
        packages = {
          inherit emacs-vterm rust;
        };
      });
}
