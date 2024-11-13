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
    document = { name, config, ... }: {
      options = {

        name = mkOption {
          description = "Symbolic name, used as a human-readable identifier";
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
        # TODO: may not need it when using `link`; could repurpose it to render the default template
        outPath = mkOption {
          description = ''
            Location of the page, used for transparently creating links
          '';
          type = types.str;
          default = lib.head config.locations;
        };
        # TODO: maybe it would even make sense to split routing and rendering altogether.
        #       in that case, templates would return strings, and a different
        #       piece of the machinery resolves rendering templates to files
        #       using `locations`.
        #       then we'd have e.g. `templates.html` and `templates.atom` for
        #       different output formats.
        template = mkOption {
          description = ''
            Function that converts the page contents to files
          '';
          type = with types; functionTo (functionTo options.files.type);
        };
      };
    };
    page = { name, config, ... }: {
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
      config.template = cfg.templates.page;
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
      config.template = lib.mkForce cfg.templates.article;
    };

    named-link = { ... }: {
      options = {
        label = mkOption {
          description = "Link label";
          type = types.str;
        };
        url = mkOption {
          description = "Link URL";
          type = types.str;
        };
      };
    };

    navigation = { name, ... }: {
      options = {
        name = mkOption {
          description = "Symbolic name, used as a human-readable identifier";
          type = types.str;
          default = name;
        };
        label = mkOption {
          description = "Menu label";
          type = types.str;
          default = name;
        };
        items = mkOption {
          description = "List of menu items";
          type = with types; listOf (attrTag {
            menu = mkOption { type = submodule cfg.content-types.navigation; };
            page = mkOption { type = submodule cfg.content-types.page; };
            link = mkOption { type = submodule cfg.content-types.named-link; };
          });
        };
      };
    };
  };
}
