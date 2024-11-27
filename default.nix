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
  # TODO: update when the PR to expose `pkgs.devmode` is merged
  #       https://github.com/NixOS/nixpkgs/pull/354556
  devmode = pkgs.callPackage "${sources.devmode-reusable}/pkgs/by-name/de/devmode/package.nix" {
    buildArgs = "${toString ./.} -A build --show-trace";
    open = "/index.html";
  };
in
rec {
  lib = lib'';
  result = lib.evalModules {
    modules = [
      ./structure
      ./content
      ./presentation
      {
        _module.args = {
          inherit pkgs;
        };
      }
    ];
  };

  inherit (result.config) build;

  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      cmark
      npins
      devmode
    ];
  };
}
