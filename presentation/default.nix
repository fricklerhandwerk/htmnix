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

  options.templates = mkOption {
    description = ''
      Collection of named helper functions for conversion different structured representations which can be rendered to a string
    '';
    # TODO: specify a more stringent type here, checking the verbal description in code
    type = with types; recursiveAttrs (functionTo (either str attrs));
  };

  # TODO: this is an artefact of exploration; needs to be adapted to actual use
  config.templates.table-of-contents =
    { config, ... }:
    let
      outline =
        { ... }:
        {
          options = {
            value = mkOption {
              # null denotes root
              type = with types; nullOr (either str (listOf (attrTag categories.phrasing)));
              subsections = mkOption {
                type = with types; listOf (submodule outline);
                default =
                  with lib;
                  map
                    # TODO: go into depth manually here,
                    #       we don't want to pollute the DOM implementation
                    (c: (lib.head (attrValues c)).outline)
                    (filter (c: isAttrs c && (lib.head (attrValues c)) ? outline) config.content);
              };
            };
            __toString = mkOption {
              type = with types; functionTo str;
              # TODO: convert to HTML
              default =
                self:
                lib.squash ''
                  ${if isNull self.value then "root" else self.value}
                  ${if self.subsections != [ ] then "  " + lib.indent "  " (lib.join "\n" self.subsections) else ""}
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
          subsections =
            with lib;
            map (c: (lib.head (attrValues c)).outline) (
              filter (c: isAttrs c && (lib.head (attrValues c)) ? outline) config.content
            );
        };
      };
    };
}
