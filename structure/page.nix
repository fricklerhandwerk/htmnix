{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
  render-html = document:
    let
      eval = lib.evalModules {
        class = "DOM";
        modules = [ document (import ../presentation/dom.nix) ];
      };
    in
    toString eval.config;
in
{
  # TODO: enable i18n, e.g. via a nested attribute for language-specific content
  options.pages = mkOption {
    description = ''
      Collection of pages on the site
    '';
    type = with types; attrsOf (submodule config.content-types.page);
  };
  config.files = with lib;
    foldl'
      (acc: elem: acc // {
        # TODO: create static redirects from `tail page.locations`
        # TODO: the file name could correspond to the canonical location in the HTML representation
        "${head elem.locations}.html" = builtins.toFile "${elem.name}.html" elem.outputs.html;
      })
      { }
      (attrValues config.pages);

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
    config.outputs.html = render-html {
      html = {
        head = {
          title.text = config.title;
          meta.description = config.description;
          link.canonical = lib.head config.locations;
        };
        body.content = [
          (cfg.menus.main.outputs.html config)
          { section.heading.content = config.title; }
          (cfg.templates.html.markdown { inherit (config) name body; })
        ];
      };
    };
  };
}
