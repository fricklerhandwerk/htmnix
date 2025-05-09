{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  imports = lib.nixFiles ./.;

  options.files = mkOption {
    description = ''
      Files that make up the site, mapping from output path to contents

      Add more files to the output by assigning to this attribute set.
    '';
    type = with types; attrsOf path;
  };

  options.out = mkOption {
    description = ''
      The final output of the web site
    '';
    type = types.package;
    default =
      let
        script =
          ''
            mkdir $out
          ''
          + lib.join "\n" copy;
        copy = lib.mapAttrsToList (path: file: ''
          mkdir -p $out/$(dirname ${path})
          cp -r ${file} $out/${path}
        '') config.files;
      in
      pkgs.runCommand "source" { } script;
  };
}
