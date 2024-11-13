{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  imports = lib.nixFiles ./.;

  options.templates =
    let
      # arbitrarily nested attribute set where the leaves are of type `type`
      recursiveAttrs = type: with types;
        # NOTE: due to how `either` works, the first match is significant,
        # so if `type` happens to be an attrset, the typecheck will consider
        # `type`, not `attrsOf`
        attrsOf (either type (recursiveAttrs type));
    in
    mkOption {
      description = ''
        Collection of named helper functions for conversion different structured representations which can be rendered to a string
      '';
      type = recursiveAttrs (with types; functionTo (either str attrs));
    };

  options.files = mkOption {
    description = ''
      Files that make up the site, mapping from output path to contents

      Add more files to the output by assigning to this attribute set.
    '';
    type = with types; attrsOf path;
  };

  options.build = mkOption {
    description = ''
      The final output of the web site
    '';
    type = types.package;
    default =
      let
        script = ''
          mkdir $out
        '' + lib.join "\n" copy;
        copy = lib.mapAttrsToList
          (
            path: file: ''
              mkdir -p $out/$(dirname ${path})
              cp -r ${file} $out/${path}
            ''
          )
          config.files;
      in
      pkgs.runCommand "source" { } script;
  };

  # TODO: this is an artefact of exploration; needs to be adapted to actual use
  config.templates.table-of-contents = { config, ... }:
    let
      outline = { ... }: {
        options = {
          value = mkOption {
            # null denotes root
            type = with types; nullOr (either str (listOf (attrTag categories.phrasing)));
            subsections = mkOption {
              type = with types; listOf (submodule outline);
              default = with lib; map
                # TODO: go into depth manually here,
                #       we don't want to pollute the DOM implementation
                (c: (lib.head (attrValues c)).outline)
                (filter (c: isAttrs c && (lib.head (attrValues c)) ? outline) config.content);
            };
          };
          __toString = mkOption {
            type = with types; functionTo str;
            # TODO: convert to HTML
            default = self: lib.squash ''
              ${if isNull self.value then "root" else self.value}
              ${if self.subsections != [] then
              "  " + lib.indent "  " (lib.join "\n" self.subsections) else ""}
            '';
          };
        };
      };
    in
    {
      options.outline = mkOption {
        type = types.submodule outline;
        default = {
          value = null;
          subsections = with lib;
            map (c: (lib.head (attrValues c)).outline)
              (filter (c: isAttrs c && (lib.head (attrValues c)) ? outline) config.content);
        };
      };
    };
}
