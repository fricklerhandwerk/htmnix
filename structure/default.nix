{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  imports = lib.nixFiles ./.;

  options.content-types = mkOption {
    description = "Content types";
    type = with types; attrsOf deferredModule;
  };

  # TODO: enable i18n, e.g. via a nested attribute for language-specific content
  options.pages = mkOption {
    description = ''
      Collection of pages on the site
    '';
    type = with types; attrsOf (submodule config.content-types.page);
  };

  options.collections = mkOption
    {
      description = ''
        Named collections of unnamed pages

        Define the content type of a new collection `example` to be `article`:

        ```nix
        config.collections.example.type = config.types.article;
        ```

        Add a new entry to the `example` collection:

        ```nix
        config.collections.example.entry = {
          # contents here
        }
        ```
      '';
      type = with types; attrsOf (submodule ({ name, config, ... }: {
        options = {
          type = mkOption {
            description = "Type of entries in the collection";
            type = types.deferredModule;
          };
          name = mkOption {
            description = "Symbolic name, used as a human-readable identifier";
            type = types.str;
            default = name;
          };
          prefixes = mkOption {
            description = ''
              List of historic output locations for files in the collection

              The first element is the canonical location.
              All other elements are used to create redirects to the canonical location.
            '';
            type = with types; nonEmptyListOf str;
            example = [ "." ];
          };
          entry = mkOption
            {
              description = "An entry in the collection";
              type = types.collection (types.submodule ({
                imports = [ config.type ];
                _module.args.collection = config;
                process-locations = ls: with lib; concatMap (l: map (p: "${p}/${l}") config.prefixes) ls;
              }));
            };
        };
      }));
    };

  options.menus = mkOption {
    description = ''
      Collection navigation menus
    '';
    type = with types; attrsOf (submodule config.content-types.navigation);
  };
}
