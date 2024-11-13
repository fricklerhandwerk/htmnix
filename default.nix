{ sources ? import ./npins
, system ? builtins.currentSystem
, pkgs ? import sources.nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  }
, lib ? import "${sources.nixpkgs}/lib"
}:
let
  lib' = final: prev:
    let
      new = import ./lib.nix { lib = final; };
    in
    new // { types = prev.recursiveUpdate prev.types new.types; };
  lib'' = lib.extend lib';
in
{
  build =
    let
      result = lib''.evalModules {
        modules = [
          ./structure
          ./content
          {
            _module.args = {
              inherit pkgs;
            };
          }
        ];
      };
    in
    result.config.build;

  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      cmark
      npins
    ];
  };
}
