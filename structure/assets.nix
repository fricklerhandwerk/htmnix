{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  options.assets = mkOption {
    description = ''
      Collection of assets, i.e. static files that can be linked to from within documents
    '';
    type =
      with types;
      attrsOf (
        submodule (
          { config, ... }:
          {
            imports = [ cfg.content-types.document ];
            options.path = mkOption {
              type = types.path;
            };
            config.outputs."" = if lib.isStorePath config.path then config.path else "${config.path}";
          }
        )
      );
    default = { };
  };

  config.files =
    with lib;
    let
      flatten =
        attrs:
        mapAttrsToList (
          _name: value:
          # HACK: we somehow have to distinguish a module value from regular attributes.
          #       arbitrary choice: the outputs attribute
          if value ? outputs then value else mapAttrsToList value
        ) attrs;
    in
    cfg.templates.files (flatten cfg.assets);
}
