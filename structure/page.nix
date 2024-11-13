{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  content-types.page = { name, config, ... }: {
    imports = [ cfg.content-types.document ];
    options = {
      title = mkOption {
        description = "Page title";
        type = types.str;
        default = name;
      };
      description = mkOption {
        description = ''
          One-sentence description of page contents
        '';
        type = types.str;
      };
      summary = mkOption {
        description = ''
          One-paragraph summary of page contents
        '';
        type = types.str;
      };
      body = mkOption {
        description = ''
          Page contents in CommonMark
        '';
        type = types.str;
      };
    };
    config.outputs.html = cfg.templates.html.page cfg config;
  };
}
