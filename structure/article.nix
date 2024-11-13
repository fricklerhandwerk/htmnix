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
    config.outputs.html = lib.mkForce (cfg.templates.html.dom {
      html = {
        head = {
          title.text = config.title;
          meta.description = config.description;
          meta.authors = if lib.isList config.author then config.author else [ config.author ];
          link.canonical = lib.head config.locations;
        };
        body.content = [
          (cfg.menus.main.outputs.html config)
          { section.heading.content = config.title; }
          (cfg.templates.html.markdown { inherit (config) name body; })
        ];
      };
    });
  };
}
