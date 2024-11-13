{ config, options, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  content-types.article = { config, collection, ... }: {
    imports = [ cfg.content-types.page ];
    options = {
      collection = mkOption {
        description = "Collection this article belongs to";
        type = options.collections.type.nestedTypes.elemType;
        default = collection;
      };
      date = mkOption {
        description = "Publication date";
        type = with types; str;
        default = null;
      };
      author = mkOption {
        description = "Page author";
        type = with types; either str (nonEmptyListOf str);
        default = null;
      };
    };
    config.name = lib.slug config.title;
    config.outputs.html = lib.mkForce ((cfg.templates.html.page config).override {
      html = {
        # TODO: make authors always a list
        head.meta.authors = if lib.isList config.author then config.author else [ config.author ];
        body.content = lib.mkForce [
          (cfg.menus.main.outputs.html config)
          {
            section = {
              heading = {
                # TODO: i18n support
                # TODO: structured dates
                before = [{ p.content = "Published ${config.date}"; }];
                content = config.title;
                after = [{ p.content = "Written by ${config.author}"; }];
              };
              content = [
                (cfg.templates.html.markdown { inherit (config) name body; })
              ];
            };
          }
        ];
      };
    });
  };
}
