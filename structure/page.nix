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
        link.stylesheets = [
          # TODO: allow enabling preload with a flag
          { href = "${page.link cfg.assets."style.css"}"; }
          { href = "${page.link cfg.assets."fonts.css"}"; }
        ];
      };
      body.content = [
        ''
          <header>
            <input type="checkbox" id="menu-toggle" hidden>
            <label for="menu-toggle" hidden>
              <svg class="menu-open" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 20 20">
               <path d="M0 4 H20 M0 10 H20 M0 16 H20" stroke="currentColor" stroke-width="2"/>
              </svg>
              <svg class="menu-close" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 20 20">
                <path d="M2 2L18 18M18 2L2 18" stroke="currentColor" stroke-width="2"/>
              </svg>
            </label>
            ${lib.indent "  " (cfg.menus.main.outputs.html page)}
          </header>
        ''
        {
          section = {
            attrs = { };
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
