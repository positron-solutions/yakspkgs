{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-22.11";
  };

  outputs = inputs: with inputs; # pass through all inputs and bring them into scope

    # Build the output set for each default system and map system sets into
    # attributes, resulting in paths such as:
    # nix build .#packages.x86_64-linux.<name>
    flake-utils.lib.eachDefaultSystem (system:

      # Same as Emacs let
      let

        # instantiate a nixpkgs
        pkgs = import nixpkgs { inherit system; };

      in rec {
        # this is the output (recursive) set (expressed for each system)

        # Everything in the profile is here in this declaration.  The
        # declaration is declarative.  What you declare is what you get.
        profile-contents = pkgs.symlinkJoin {
          name = "emacs-profile-god-1998";
          paths = [ pkgs.hello pkgs.cowsay ];
        };

        # the packages in `nix build .#packages.<system>.<name>`
        packages = {
          # nix build .#bigger-project
          # nix build .#packages.x86_64-linux.bigger-project
          inherit profile-contents;
          # nix build
          default = packages.profile-contents;
        };
      }
    );
}
