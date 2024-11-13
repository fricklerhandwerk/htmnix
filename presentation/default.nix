{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  templates = import ./templates.nix { inherit lib; };
in
{
  options.templates = mkOption {
    description = ''
      Collection of named functions to convert page contents to files

      Each template function takes the complete site `config` and the page data structure.
    '';
    type = with types; attrsOf (functionTo (functionTo options.files.type));
  };

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
        ${page.outPath} = builtins.toFile "${page.name}.html" (templates.html {
          head = ''
            <title>${page.title}</title>
            <meta name="description" content="${page.description}" />
            <link rel="canonical" href="${page.outPath}" />
          '';
          body = builtins.readFile (commonmark page.name page.body);
        });
      });
      article = lib.mkDefault (config: page: {
        # TODO: create static redirects from `tail page.locations`
        ${page.outPath} = builtins.toFile "${page.name}.html" (templates.html {
          head = ''
            <title>${page.title}</title>
            <meta name="description" content="${page.description}" />
            <meta name="author" content="${with lib; if isList page.author then join ", " page.author else page.author}" />
          '';
          body = builtins.readFile (commonmark page.name page.body);
        });
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
