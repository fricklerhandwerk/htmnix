{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  templates = import ./templates.nix { inherit lib; };
in
{
  options.templates =
    let
      # arbitrarily nested attribute set where the leaves are of type `type`
      # NOTE: due to how `either` works, the first match is significant,
      # so if `type` happens to be an attrset, the typecheck will consider
      # `type`, not `attrsOf`
      recursiveAttrs = type: with types; attrsOf (either type (recursiveAttrs type));
    in
    mkOption {
      description = ''
        Collection of named functions to convert document contents to a string representation

        Each template function takes the complete site `config` and the document's data structure.
      '';
      # TODO: this function should probably take a single attrs,
      #       otherwise it's quite inflexible.
      #       named parameters would also help with readability at the call site
      type = recursiveAttrs (with types; functionTo (functionTo str));
    };

  config.templates.html =
    let
      commonmark = name: markdown: pkgs.runCommand "${name}.html"
        {
          buildInputs = [ pkgs.cmark ];
        } ''
        cmark ${builtins.toFile "${name}.md" markdown} > $out
      '';
    in
    {
      nav = lib.mkDefault templates.nav;
      page = lib.mkDefault (config: page: templates.html {
        head = ''
          <title>${page.title}</title>
          <meta name="description" content="${page.description}" />
          <link rel="canonical" href="${page.outPath}" />
        '';
        body = ''
          ${config.menus.main.outputs.html page}
          ${builtins.readFile (commonmark page.name page.body)}
        '';
      });
      article = lib.mkDefault (config: page: templates.html {
        head = ''
          <title>${page.title}</title>
          <meta name="description" content="${page.description}" />
          ${with lib; join "\n" (map
          (author: ''<meta name="author" content="${author}" />'')
          (if isList page.author then page.author else [page.author]))
          }
        '';
        body = ''
          ${config.menus.main.outputs.html page}
          ${builtins.readFile (commonmark page.name page.body)}
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
    # TODO: create static redirects from `tail page.locations`
    let
      pages = lib.attrValues config.pages;
      collections = with lib; concatMap (collection: collection.entry) (attrValues config.collections);
    in
    with lib; foldl
      (acc: elem: acc // {
        # TODO: we may or may not want to enforce the mapping of file types to output file name suffixes
        "${head elem.locations}.html" = builtins.toFile "${elem.name}.html" elem.outputs.html;
      })
      { }
      (pages ++ collections);

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
