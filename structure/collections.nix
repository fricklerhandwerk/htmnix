{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  options.collections = mkOption {
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

            The default entry is the symbolic name of the collection.
            When changing the symbolic name, append the old one to your custom list and use `lib.mkForce` to make sure the default element will be overridden.
          '';
          type = with types; nonEmptyListOf str;
          example = [ "." ];
          default = [ config.name ];
        };
        entry = mkOption {
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
  config.files =
    # TODO: create static redirects from `tail <collection>.locations`
    let
      collections = with lib; concatMap (collection: collection.entry) (attrValues config.collections);
    in
    with lib; foldl
      (acc: elem: acc // {
        "${head elem.locations}.html" = builtins.toFile "${elem.name}.html" "${elem.outputs.html}";
      })
      { }
      collections;
}
