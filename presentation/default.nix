{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  templates = import ./templates.nix { inherit lib; };
  # TODO: optionally run the whole thing through the validator
  # https://github.com/validator/validator
  render-html = document:
    let
      eval = lib.evalModules {
        class = "DOM";
        modules = [ document (import ./dom.nix) ];
      };
    in
    toString eval.config;
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

  config.templates.html = {
    markdown = name: text:
      let
        commonmark = pkgs.runCommand "${name}.html"
          {
            buildInputs = [ pkgs.cmark ];
          } ''
          cmark ${builtins.toFile "${name}.md" text} > $out
        '';
      in
      builtins.readFile commonmark;
    nav = menu: page:
      let
        render-item = item:
          if item ? menu then ''
            <li>${item.menu.label}
              ${lib.indent "  " (item.menu.outputs.html page)}
            </li>
          ''
          else if item ? page then ''<li><a href="${page.link item.page}">${item.page.title}</a></li>''
          else ''<li><a href="${item.link.url}">${item.link.label}</a></li>''
        ;
      in
      ''
        <nav>
          <ul>
            ${with lib; indent "    " (join "\n" (map render-item menu.items))}
          </ul>
        </nav>
      '';

  };

  options.files = mkOption {
    description = ''
      Files that make up the site, mapping from output path to contents

      By default, all elements in `option`{pages} are converted to files using their template or the default template.
      Add more files to the output by assigning to this attribute set.
    '';
    # TODO: this should be attrsOf string-coercible instead.
    #       we can convert this to file at the very end.
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

  # TODO: this is an artefact of exploration; needs to be adapted to actual use
  config.templates.table-of-contents = { config, ... }:
    let
      outline = { ... }: {
        options = {
          value = mkOption {
            # null denotes root
            type = with types; nullOr (either str (listOf (attrTag categories.phrasing)));
            subsections = mkOption {
              type = with types; listOf (submodule outline);
              default = with lib; map
                # TODO: go into depth manually here,
                #       we don't want to pollute the DOM implementation
                (c: (lib.head (attrValues c)).outline)
                (filter (c: isAttrs c && (lib.head (attrValues c)) ? outline) config.content);
            };
          };
          __toString = mkOption {
            type = with types; functionTo str;
            # TODO: convert to HTML
            default = self: lib.squash ''
              ${if isNull self.value then "root" else self.value}
              ${if self.subsections != [] then
              "  " + lib.indent "  " (lib.join "\n" self.subsections) else ""}
            '';
          };
        };
      };
    in
    {
      options.outline = mkOption {
        type = types.submodule outline;
        default = {
          value = null;
          subsections = with lib;
            map (c: (lib.head (attrValues c)).outline)
              (filter (c: isAttrs c && (lib.head (attrValues c)) ? outline) config.content);
        };
      };
    };
}
