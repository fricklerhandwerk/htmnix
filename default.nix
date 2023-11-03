{ inputs ? import ./nix/sources.nix }:
let
  pkgs = import inputs.nixpkgs { config = { }; overlays = [ ]; };
  pkgs-unstable = import inputs.nixpkgs-unstable { config = { }; overlays = [ ]; };
  nix-unit = (pkgs-unstable.callPackage inputs.nix-unit {
    srcDir = inputs.nix-unit;
    nix = pkgs-unstable.nixUnstable;
  });
in
{
  lib.htmnix = modules: pkgs.lib.evalModules {
    class = "htmnix";
    modules = modules ++ [ (import ./modules/document.nix) ];
  };

  shell = pkgs.mkShell {
    packages = [
      nix-unit
    ];
  };
}
