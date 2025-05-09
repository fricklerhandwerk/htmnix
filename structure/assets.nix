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
      Collection of assets: files that can be linked to from within documents
    '';
    type = with types; attrsOf (submodule (config.content-types.asset));
  };

  config.content-types.asset =
    { ... }:
    {
      imports = [ cfg.content-types.document ];

      options.path = mkOption {
        description = "File system path to the asset";
        type = types.path;
      };
      # XXX: the "" output type means raw files
      config.outputs."" = if lib.isStorePath config.path then config.path else "${config.path}";
    };

  config.files =
    with lib;
    let
      flatten =
        attrs:
        mapAttrsToList (
          _name: value:
          # HACK: we somehow have to distinguish a module value from regular attributes.
          #       (almost) arbitrary choice, since we always deal with documents:
          #       the `outputs` attribute
          if value ? outputs then value else mapAttrsToList value
        ) attrs;
    in
    cfg.templates.files (flatten cfg.assets);
}
