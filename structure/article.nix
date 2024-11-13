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
    config.outputs.html = lib.mkForce (cfg.templates.html.article cfg config);
  };
}
