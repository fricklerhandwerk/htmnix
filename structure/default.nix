{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
  types' = import ./types.nix { inherit lib; } // {
    article = { config, collectionName, ... }: {
      imports = [ types'.page ];
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
        template = mkOption
          {
            description = ''
              Function that converts the page contents to files
            '';
            type = with types; functionTo (functionTo options.files.type);
            default = cfg.templates.page;
          };
      };
    };
  };
in
{
  # TODO: split out:
  # - extra module system types into lib'
  # - page and article types into their own module values under structure/${page,article}.nix
  #   yes, actually. those types should probably be configurable
  config.collections.news.type = types'.article;

  options.pages = mkOption {
    description = ''
      Collection of pages on the site
    '';
    type = with types; attrsOf (submodule types'.page);
  };

  options.collections = mkOption
    {
      description = ''
        Named collections of unnamed pages
      '';
      type = with types; attrsOf (submodule ({ name, config, ... }: {
        options = {
          type = mkOption {
            description = "Type of entries in the collection";
            type = types.deferredModule;
          };
          entry = mkOption {
            description = "An entry in the collection";
            type = types'.collection (types.submodule ({
              _module.args.collection = config.entry;
              _module.args.collectionName = name;
              imports = [ config.type ];
            }));
          };
        };
      }));
    };

  options.templates = mkOption {
    description = ''
      Collection of named functions to convert page contents to files

      Each template function takes the complete site `config` and the page data structure.
    '';
    type = with types; attrsOf (functionTo (functionTo options.files.type));
  };
  # TODO: split out templates and all related helper junk into `../presentation`
  config.templates =
    let
      commonmark = name: markdown: pkgs.runCommand "${name}.html"
        {
          buildInputs = [ pkgs.cmark ];
        } ''
        cmark ${builtins.toFile "${name}.md" markdown} > $out
      '';
    in
    {
      page = lib.mkDefault (config: page: {
        # TODO: create static redirects from `tail page.locations`
        # TODO: reconsider using `page.outPath` and what to put into `locations`.
        #       maybe we can avoid having ".html" suffixes there.
        #       since templates can output multiple files, `html` is merely one of many things we *could* produce.
        ${page.outPath} = builtins.toFile "${page.name}.html" ''
          <html>
          <head>
          <meta charset="utf-8" />
          <meta http-equiv="X-UA-Compatible" content="IE=edge" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />

          <title>${page.title}</title>
          <meta name="description" content="${page.description}" />
          <link rel="canonical" href="${page.outPath}" />
          </head>
          <body>
          ${lib.indent "  " (builtins.readFile (commonmark page.name page.body))}
          <body>
          </html>
        '';
      });
      article = lib.mkDefault (config: page: {
        # TODO: create static redirects from `tail page.locations`
        ${page.outPath} = builtins.toFile "${page.name}.html" ''
          <html>
          <head>
          <meta charset="utf-8" />
          <meta http-equiv="X-UA-Compatible" content="IE=edge" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />

          <title>${page.title}</title>
          <meta name="description" content="${page.description}" />
          ${with lib;
            if ! isNull page.author then
            ''<meta name="author" content="${if isList page.author then join ", " page.author else page.author}" />''
            else ""
          }
          <link rel="canonical" href="${page.outPath}" />
          </head>
          <body>
          ${lib.indent "  " (builtins.readFile (commonmark page.name page.body))}
          <body>
          </html>
        '';
      });
    };

  options.files = mkOption {
    description = ''
      Files that make up the site, mapping from output path to contents

      By default, all elements in `option`{pages} are converted to files using their template or the default template.
      Add more files to the output by assigning to this attribute set.
    '';
    type = with types; attrsOf path;
  };
  config.files =
    let
      pages = lib.concatMapAttrs
        (name: page: page.template config page)
        config.pages;
      collections =
        let
          byCollection = with lib; mapAttrs
            (_: collection:
              map (entry: entry.template config entry) collection.entry
            )
            config.collections;
        in
        with lib; concatMapAttrs
          (collection: entries:
            foldl' (acc: entry: acc // entry) { } entries
          )
          byCollection;
    in
    pages // collections;


  options.build = mkOption {
    description = ''
      The final output of the web site
    '';
    type = types.package;
    default =
      let
        script = ''
          mkdir $out
        '' + lib.join "\n" copy;
        copy = lib.mapAttrsToList
          (
            path: file: ''
              mkdir -p $out/$(dirname ${path})
              cp -r ${file} $out/${path}
            ''
          )
          config.files;
      in
      pkgs.runCommand "source" { } script;
  };
}
