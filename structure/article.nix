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
    config.outputs.html = lib.mkForce
      ((cfg.templates.html.page config).override (final: prev: {
        html = {
          # TODO: make authors always a list
          head.meta.authors = if lib.isList config.author then config.author else [ config.author ];
          body.content = with lib; map
            (e:
              if isAttrs e && e ? section
              then
                recursiveUpdate e
                  {
                    section.heading = {
                      before = [{ p.content = "Published ${config.date}"; }];
                      after = [{ p.content = "Written by ${config.author}"; }];
                    };
                  }
              else e
            )
            prev.html.body.content;
        };
      }));
  };
}
