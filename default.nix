{ inputs ? import ./nix/sources.nix }:
let
  pkgs = import inputs.nixpkgs { config = { }; overlays = [ ]; };
  pkgs-unstable = import inputs.nixpkgs-unstable { config = { }; overlays = [ ]; };
  eval = modules: pkgs.lib.evalModules {
    class = "htmnix";
    specialArgs = { inherit (pkgs) lib; };
    modules = modules ++ [ (import ./modules/document.nix) ];
  };
  renderDocument = doc: ''
    <html>
    <meta>
      <title>${doc.meta.title}</title>
    </meta>
    </html>
  '';
  nix-unit = (pkgs-unstable.callPackage inputs.nix-unit {
    srcDir = inputs.nix-unit;
    nix = pkgs-unstable.nixUnstable;
  });
in
{
  inherit eval renderDocument;
  devShells.default = pkgs.mkShell {
    packages = [
      nix-unit
    ];
  };
}
