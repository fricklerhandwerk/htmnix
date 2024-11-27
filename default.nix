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

  shell =
    let
      run-tests = pkgs.writeShellApplication {
        name = "run-tests";
        text = with pkgs; with lib; ''
          ${getExe nix-unit} ${toString ./tests.nix} "$@"
        '';
      };
      test-loop = pkgs.writeShellApplication {
        name = "test-loop";
        text = with pkgs; with lib; ''
          ${getExe watchexec} -w ${toString ./.} -- ${getExe nix-unit} ${toString ./tests.nix}
        '';
      };
      devmode = pkgs.devmode.override {
        buildArgs = "${toString ./.} -A build --show-trace";
        open = "/index.html";
      };
    in
    pkgs.mkShellNoCC {
      packages = [
        pkgs.npins
        run-tests
        test-loop
        devmode
      ];
    };

  tests = with pkgs; with lib; runCommand "run-tests" { } ''
    touch $out
    ${getExe nix-unit} ${./tests.nix} "$@"
  '';
}
