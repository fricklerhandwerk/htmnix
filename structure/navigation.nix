{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
  subtype = baseModule: types.submodule [
    baseModule
    { _module.freeformType = types.attrs; }
  ];
in
{
  content-types.named-link = { ... }: {
    options = {
      label = mkOption {
        description = "Link label";
        type = types.str;
      };
      url = mkOption {
        description = "Link URL";
        type = types.str;
      };
    };
  };

  content-types.navigation = { name, ... }: {
    options = {
      name = mkOption {
        description = "Symbolic name, used as a human-readable identifier";
        type = types.str;
        default = name;
      };
      label = mkOption {
        description = "Menu label";
        type = types.str;
        default = name;
      };
      items = mkOption {
        description = "List of menu items";
        type = with types; listOf (attrTag {
          menu = mkOption { type = submodule cfg.content-types.navigation; };
          page = mkOption { type = subtype cfg.content-types.page; };
          link = mkOption { type = submodule cfg.content-types.named-link; };
        });
      };
    };
  };
}
