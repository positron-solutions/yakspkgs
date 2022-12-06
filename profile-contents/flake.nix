{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-22.11";
    description = "This is an empty flake used to bootstrap the profile with a dummy package."
  };
  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        profile-contents = pkgs.symlinkJoin {
          name = "emacs-profile";
          paths = [
            # Just add packages here and you have a package set that can be
            # installed into a profile.

            # pkgs.hello
            # pkgs.cowsay
          ];
        };
      in rec {
        packages = {
          inherit profile-contents;
          default = packages.profile-contents;
        };
      }
    );
}
