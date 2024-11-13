{ sources ? import ./npins
, system ? builtins.currentSystem
, pkgs ? import sources.nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  }
, lib ? import "${sources.nixpkgs}/lib"
,
}:
let
  lib' = pkgs.callPackage ./lib.nix { };
in
{
  site = lib'.site "fediversity.eu" ./content;

  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      cmark
      npins
    ];
  };
}
