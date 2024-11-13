{ config, options, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  content-types.event = { config, collection, ... }: {
    imports = [ cfg.content-types.page ];
    options = {
      collection = mkOption {
        description = "Collection this event belongs to";
        type = options.collections.type.nestedTypes.elemType;
        default = collection;
      };
      start-date = mkOption {
        description = "Start date of the event";
        type = with types; str;
      };
      start-time = mkOption {
        description = "Start time of the event";
        type = with types; str;
        default = null;
      };
      end-date = mkOption {
        description = "End date of the event";
        type = with types; str;
        default = null;
      };
      end-time = mkOption {
        description = "End time of the event";
        type = with types; str;
        default = null;
      };
      location = mkOption {
        description = "Location of the event";
        type = with types; str;
      };
    };
    config.name = lib.slug config.title;
    config.summary = lib.mkDefault config.description;
    config.outputs.html = lib.mkForce
      ((cfg.templates.html.page config).override (final: prev: {
        html.body.content = with lib; map
          (e:
            if isAttrs e && e ? section
            then
              recursiveUpdate e
                {
                  section.content = [
                    {
                      dl.content = [
                        {
                          terms = [{ dt = "Location"; }];
                          descriptions = [{ dd = config.location; }];
                        }
                        {
                          terms = [{ dt = "Start"; }];
                          descriptions = [{
                            dd = config.start-date + lib.optionalString (!isNull config.start-time) " ${config.start-time}";
                          }];
                        }
                      ] ++ lib.optional (!isNull config.end-date) {
                        terms = [{ dt = "End"; }];
                        descriptions = [{
                          dd = config.end-date + lib.optionalString (!isNull config.end-time) " ${config.end-time}";
                        }];
                      };
                    }
                  ]
                  ++ e.section.content;
                }
            else e
          )
          prev.html.body.content;

      }));
  };
}
