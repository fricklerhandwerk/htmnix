let
  sources = import ./npins;
in
{
  nixpkgs ? sources.nixpkgs,
}:
let
  lib = import "${sources.nixpkgs}/lib";
  lib' =
    final: prev:
    let
      new = import ./lib.nix { lib = final; };
    in
    new // { types = prev.recursiveUpdate prev.types new.types; };
  lib'' = lib.extend lib';
in
{
  lib = lib'';
  nixpkgs =
    {
      system ? builtins.currentSystem,
      config ? { },
      overlays ? [ ],
    }@nixpkgs-config:
    let
      pkgs = import nixpkgs ({ inherit system config overlays; } // nixpkgs-config);
      tests = pkgs.writeShellApplication {
        name = "tests";
        runtimeInputs = with pkgs; [ nix-unit ];
        text = ''
          exec nix-unit ${toString ./tests.nix} "$@"
        '';
      };
      test-loop = pkgs.writeShellApplication {
        name = "test-loop";
        runtimeInputs = [
          pkgs.watchexec
          tests
        ];
        text = ''
          exec watchexec -w ${toString ./.} -- tests "$@"
        '';
      };
    in
    {
      # re-export inputs so they can be overridden granularly
      # (they can't be accessed from the outside any other way)
      inherit sources pkgs;
      shell = pkgs.mkShellNoCC {
        packages = lib.attrValues {
          inherit (pkgs) npins;
          inherit tests test-loop;
        };
      };
    };
}
