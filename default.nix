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
  join = lib.concatStringsSep;
in
{
  site = pkgs.stdenv.mkDerivation {
    name = "fediversity.eu";
    src = ./content;
    buildPhase = ''
      true
    '';
    installPhase = ''
      mkdir $out
    '' + join "\n" (lib.mapAttrsToList
      (name: value: ''
        cp ${value} $out/${name}
      '')
      (lib'.files ./content));
  };
  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      cmark
      npins
    ];
  };
}
