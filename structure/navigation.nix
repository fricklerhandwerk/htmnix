{ config, options, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
  subtype = baseModule: types.submodule [
    baseModule
    {
      _module.freeformType = types.attrs;
      # XXX: this is supposed to be used with a finished value,
      #      and we don't want to process locations again.
      process-locations = lib.mkForce lib.id;
    }
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

  content-types.navigation = { name, config, ... }: {
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
      outputs = mkOption {
        description = ''
          Representations of the navigation structure in different formats

          It must be a function that takes the page on which the navigation is to be shown, such that relative links get computed correctly.
        '';
        type = with types; attrsOf (functionTo str);
        default.html = page: cfg.templates.html.nav {
          menu = config; inherit page;
        };
      };
    };
  };
}
