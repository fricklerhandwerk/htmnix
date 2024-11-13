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
        # TODO: reconsider using `page.outPath` and what to put into `locations`.
        #       maybe we can avoid having ".html" suffixes there.
        #       since templates can output multiple files, `html` is merely one of many things we *could* produce.
        # TODO: make `apply` configurable so one can programmatically modify locations
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
        outputs = mkOption {
          description = ''
            Representations of the document in different formats
          '';
          type = with types; attrsOf str;
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
      config.outputs.html = cfg.templates.html.page cfg config;
    };

    article = { config, collection, ... }: {
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
      # TODO: this should be covered by the TBD `link` function instead,
      #       taking a historical list of collection names into account
      config.outPath = "${collection.name}/${lib.head config.locations}";
      config.outputs.html = lib.mkForce (cfg.templates.html.article cfg config);
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
