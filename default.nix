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
{
  build =
    let
      result = pkgs.lib.evalModules {
        modules = [
          ./structure
          ./content
          { _module.args = { inherit pkgs; }; }
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
