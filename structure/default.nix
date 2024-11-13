{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  imports = [ ./content-types.nix ];

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
          entry = mkOption {
            description = "An entry in the collection";
            type = types.collection (types.submodule ({
              _module.args.collection = config.entry;
              _module.args.collectionName = name;
              imports = [ config.type ];
            }));
          };
        };
      }));
    };

}
