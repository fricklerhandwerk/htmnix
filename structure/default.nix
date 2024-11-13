{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  cfg = config;
in
{
  options.pages = mkOption {
    description = ''
      Collection of pages on the site
    '';
    type = with types; attrsOf (submodule ({ name, config, ... }:
      {
        options = {
          title = mkOption {
            type = types.str;
          };
          locations = mkOption {
            description = ''
              List of historic output locations for the resulting file

              The first element is the canonical location.
              All other elements are used to create redirects to the canonical location.
            '';
            type = with types; nonEmptyListOf str;
          };
          outPath = mkOption {
            description = ''
              Canonical location of the page
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
              type = with types; functionTo (functionTo (functionTo options.files.type));
              default = cfg.templates.default;
            };
        };
      }));
  };

  options.templates = mkOption {
    description = ''
      Collection of named functions to convert page contents to files
    '';
    type = with types; attrsOf (functionTo (functionTo (functionTo options.files.type)));
  };
  config.templates.default =
    let
      commonmark = name: markdown: pkgs.runCommand "${name}.html"
        {
          buildInputs = [ pkgs.cmark ];
        } ''
        cmark ${builtins.toFile "${name}.md" markdown} > $out
      '';
    in
    lib.mkDefault
      (config: name: page: {
        # TODO: create static redirects from the tail
        ${lib.head page.locations} = builtins.toFile "${name}.html" ''
          <html>
          <head>
          <meta charset="utf-8" />
          <meta http-equiv="X-UA-Compatible" content="IE=edge" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />

          <title>${page.title}</title>
          <meta name="description" content="${page.description}" />
          <link rel="canonical" href="${lib.head page.locations}" />
          </head>
          <body>
          ${builtins.readFile (commonmark name page.body)}
          <body>
          </html>
        '';
      });

  options.files = mkOption {
    description = ''
      Files that make up the site, mapping from output path to contents

      By default, all elements in `option`{pages} are converted to files using their template or the default template.
      Add more files to the output by assigning to this attribute set.
    '';
    type = with types; attrsOf path;
  };
  config.files = lib.concatMapAttrs
    (name: page: page.template config name page)
    config.pages;

  options.build = mkOption {
    description = ''
      The final output of the web site
    '';
    type = types.package;
    default =
      let
        script = ''
          mkdir $out
        '' + lib.concatStringsSep "\n" copy;
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
