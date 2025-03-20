{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  pkgs ? import sources.nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  },
  lib ? import "${sources.nixpkgs}/lib",
}:
let
  lib' =
    final: prev:
    let
      new = import ./lib.nix { lib = final; };
    in
    new // { types = prev.recursiveUpdate prev.types new.types; };
  lib'' = lib.extend lib';

in
rec {
  # re-export inputs so they can be overridden granularly
  # (they can't be accessed from the outside any other way)
  inherit sources pkgs;

  lib = lib'';

  # pass a suitable module as `content`
  build =
    content:
    let
      result = lib.evalModules {
        modules = [
          content
          ./structure
          ./presentation
          {
            _module.args = {
              inherit pkgs;
            };
          }
        ];
      };
    in
    result.config.build;

  shell =
    let
      run-tests = pkgs.writeShellApplication {
        name = "run-tests";
        text =
          with pkgs;
          with lib;
          ''
            ${getExe nix-unit} ${toString ./tests.nix} "$@"
          '';
      };
      test-loop = pkgs.writeShellApplication {
        name = "test-loop";
        text =
          with pkgs;
          with lib;
          ''
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

  tests =
    with pkgs;
    with lib;
    let
      source = fileset.toSource {
        root = ../.;
        fileset = fileset.unions [
          ./default.nix
          ./tests.nix
          ./lib.nix
          ../npins
        ];
      };
    in
    runCommand "run-tests"
      {
        buildInputs = [ pkgs.nix ];
      }
      ''
        export HOME="$(realpath .)"
        # HACK: nix-unit initialises its own entire Nix, so it needs a store to operate on,
        # but since we're in a derivation, we can't fetch sources, so copy Nixpkgs manually here.
        # `''${sources.nixpkgs}` resolves to `<hash>-source`,
        # adding it verbatim will result in <hash'>-<hash>-source, so rename it first
        cp -r ${sources.nixpkgs} source
        nix-store --add --store "$HOME" source
        ${getExe nix-unit} --gc-roots-dir "$HOME" --store "$HOME" ${source}/website/tests.nix "$@"
        touch $out
      '';
}
