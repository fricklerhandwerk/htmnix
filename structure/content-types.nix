{ config, lib, options, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  options = {
    content-types = mkOption {
      description = "Content types";
      type = with types; attrsOf deferredModule;
    };
  };
  config.content-types = {
    page = { name, config, ... }: {
      options = {
        name = mkOption {
          description = "Symbolic name for the page, used as a human-readable identifier";
          type = types.str;
          default = name;
        };
        title = mkOption {
          description = "Page title";
          type = types.str;
          default = name;
        };
        locations = mkOption {
          description = ''
            List of historic output locations for the resulting file

            The first element is the canonical location.
            All other elements are used to create redirects to the canonical location.
          '';
          type = with types; nonEmptyListOf str;
        };
        link = mkOption {
          description = "Helper function for transparent linking to other pages";
          type = with types; functionTo str;
          default = target: "TODO: compute the relative path based on `locations`";
        };
        outPath = mkOption {
          description = ''
            Location of the page, used for transparently creating links
          '';
          type = types.str;
          default = lib.head config.locations;
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
        template = mkOption {
          description = ''
            Function that converts the page contents to files
          '';
          type = with types; functionTo (functionTo options.files.type);
          default = cfg.templates.page;
        };
      };
    };

    article = { config, collectionName, ... }: {
      imports = [ cfg.content-types.page ];
      options = {
        date = mkOption {
          description = "Publication date";
          type = with types; nullOr str;
          default = null;
        };
        author = mkOption {
          description = "Page author";
          type = with types; nullOr (either str (listOf str));
          default = null;
        };
      };
      config.name = lib.slug config.title;
      config.outPath = "${collectionName}/${lib.head config.locations}";
      config.template = cfg.templates.article;
    };
  };
}
