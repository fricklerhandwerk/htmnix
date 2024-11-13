{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  # TODO: enable i18n, e.g. via a nested attribute for language-specific content
  options.pages = mkOption {
    description = ''
      Collection of pages on the site
    '';
    type = with types; attrsOf (submodule config.content-types.page);
  };

  config.files = with lib; cfg.templates.files (attrValues config.pages);

  config.content-types.page = { name, config, ... }: {
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

    config.outputs.html = cfg.templates.html.page config;
  };

  config.templates.html.page = lib.template cfg.templates.html.dom (page: {
    html = {
      head = {
        title.text = page.title;
        meta.description = page.description;
        link.canonical = lib.head page.locations;
      };
      body.content = [
        (cfg.menus.main.outputs.html page)
        {
          section = {
            heading.content = page.title;
            content = [
              (cfg.templates.html.markdown { inherit (page) name body; })
            ];
          };
        }
      ];
    };
  });
}
