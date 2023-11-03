{ inputs ? import ./nix/sources.nix }:
let
  pkgs = import inputs.nixpkgs { config = { }; overlays = [ ]; };
  pkgs-unstable = import inputs.nixpkgs-unstable { config = { }; overlays = [ ]; };
  eval = modules: pkgs.lib.evalModules {
    class = "htmnix";
    specialArgs = { inherit (pkgs) lib; };
    modules = modules ++ [ (import ./modules/document.nix) ];
  };
  nix-unit = (pkgs-unstable.callPackage inputs.nix-unit {
    srcDir = inputs.nix-unit;
    nix = pkgs-unstable.nixUnstable;
  });
in
{
  inherit eval;
  devShells.default = pkgs.mkShell {
    packages = [
      nix-unit
    ];
  };
}
