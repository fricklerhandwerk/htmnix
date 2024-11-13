/**
  A strongly typed module system implementation of the Document Object Model (DOM)

  Based on the WHATWG's HTML Living Standard https://html.spec.whatwg.org (CC-BY 4.0)
  Inspired by https://github.com/knupfer/type-of-html by @knupfer (BSD-3-Clause)
  Similar work from the OCaml ecosystem: https://github.com/ocsigen/tyxml
*/
{ lib, ... }:
let
  inherit (lib) mkOption types;

  # https://html.spec.whatwg.org/multipage/dom.html#content-models
  # https://html.spec.whatwg.org/multipage/dom.html#kinds-of-content
  content-categories = [
    "none" # https://html.spec.whatwg.org/multipage/dom.html#the-nothing-content-model
    "text" # https://html.spec.whatwg.org/multipage/dom.html#text-content
    "metadata" # https://html.spec.whatwg.org/multipage/dom.html#metadata-content
    "flow" # https://html.spec.whatwg.org/multipage/dom.html#flow-content
    "sectioning" # https://html.spec.whatwg.org/multipage/dom.html#sectioning-content
    "heading" # https://html.spec.whatwg.org/multipage/dom.html#heading-content
    "phrasing" # https://html.spec.whatwg.org/multipage/dom.html#phrasing-content
    "embedded" # https://html.spec.whatwg.org/multipage/dom.html#embedded-content-2
    "interactive" # https://html.spec.whatwg.org/multipage/dom.html#interactive-content
    "palpable" # https://html.spec.whatwg.org/multipage/dom.html#palpable-content
    "scripting" # https://html.spec.whatwg.org/multipage/dom.html#script-supporting-elements
  ];

  # base type for all DOM elements
  element = { name, config, ... }: {
    # TODO: add fields for upstream documentation references
    # TODO: programmatically generate documentation
    options = with lib; {
      categories = mkOption {
        type = types.listOfUnique (types.enum content-categories);
      };
      __toString = mkOption {
        internal = true;
        type = with types; functionTo str;
      };
    };
  };

  # options with types for all the defined DOM elements
  element-types = lib.mapAttrs
    (name: value: mkOption { type = types.submodule value; })
    elements;

  # attrset of categories, where values are module options with the type of the
  # elements that belong to these categories
  categories = with lib;
    genAttrs
      content-categories
      (category:
        (mapAttrs (_: e: mkOption { type = types.submodule e; })
          # HACK: don't evaluate the submodule types, just grab the config directly
          (filterAttrs (_: e: elem category (e { name = "dummy"; }).config.categories) elements))
      );

  global-attrs = lib.mapAttrs (name: value: mkOption value) {
    class = {
      type = with types; listOf nonEmptyStr;
      default = [ ];
    };
    hidden = {
      type = types.bool;
      default = false;
    };
    id = {
      type = with types; nullOr nonEmptyStr;
      default = null;
    };
    lang = {
      # TODO: https://www.rfc-editor.org/rfc/rfc5646.html
      type = with types; nullOr str;
      default = null;
    };
    style = {
      # TODO: CSS type ;..)
      type = with types; nullOr str;
      default = null;
    };
    title = {
      type = with types; nullOr lines;
      default = null;
    };
    # TODO: more global attributes
    # https://html.spec.whatwg.org/#global-attributes
    # https://html.spec.whatwg.org/#attr-aria-*
    # https://html.spec.whatwg.org/multipage/microdata.html#encoding-microdata
  };

  attrs = lib.mapAttrs (name: value: mkOption value) {
    href = {
      # TODO: https://url.spec.whatwg.org/#valid-url-string
      # ;..O
      type = types.str;
    };
    target = {
      # https://html.spec.whatwg.org/multipage/document-sequences.html#valid-navigable-target-name-or-keyword
      type =
        let
          is-valid-target = s:
            let
              inherit (lib) match;
              has-lt = s: match ".*<.*" s != null;
              has-tab-or-newline = s: match ".*[\t\n].*" s != null;
              has-valid-start = s: match "^[^_].*$" s != null;
            in
            has-valid-start s && !(has-lt s && has-tab-or-newline s);
        in
        with types; either
          (enum [ "_blank" "_self" "_parent" "_top" ])
          (types.addCheck str is-valid-target)
      ;
    };
  };

  mkAttrs = attrs: with lib;
    mkOption {
      type = types.submodule {
        options = global-attrs // attrs;
      };
      default = { };
    };

  print-attrs = with lib; attrs:
    # TODO: figure out how let attributes know how to print themselves without polluting the interface
    let
      result = trim (join " "
        (mapAttrsToList
          # TODO: this needs to be smarter for boolean attributes
          #       where the value must be written out explicitly.
          #       probably the attribute itself should have its own `__toString`.
          (name: value:
            if isBool value then
              if value then name else ""
            # TODO: some attributes must be explicitly empty
            else optionalString (toString value != "") ''${name}="${toString value}"''
          )
          attrs)
      );
    in
    optionalString (stringLength result > 0) " " + result
  ;

  print-element = name: attrs: content:
    with lib;
    lib.squash ''
      <${name}${print-attrs attrs}>
        ${lib.indent "  " content}
      </${name}>
    '';

  elements = rec {
    document = { ... }: {
      imports = [ element ];
      options = {
        inherit (element-types) html;
        attrs = mkAttrs { };
      };

      config.categories = [ ];
      config.__toString = self: ''
        <!DOCTYPE HTML >
        ${self.html}
      '';
    };

    html = { name, ... }: {
      imports = [ element ];
      options = {
        attrs = mkAttrs { };
        inherit (element-types) head body;
      };

      config.categories = [ ];
      config.__toString = self: print-element name self.attrs ''
        ${self.head}
        ${self.body}
      '';
    };

    head = { name, ... }: {
      imports = [ element ];
      options = with lib; {
        attrs = mkAttrs { };
        # https://html.spec.whatwg.org/multipage/semantics.html#the-head-element:concept-element-content-model
        # XXX: this doesn't implement the iframe srcdoc semantics
        #      as those have questionable value and would complicate things a bit.
        #      it should be possible though, by passing a flag via module arguments.
        inherit (element-types) title;
        base = mkOption {
          type = with types; nullOr (submodule base);
          default = null;
        };
        # https://html.spec.whatwg.org/multipage/semantics.html#attr-meta-charset
        meta.charset = mkOption {
          # TODO: create programmatically from https://encoding.spec.whatwg.org/encodings.json
          type = types.enum [
            "utf-8"
          ];
          default = "utf-8";
        };
        # https://developer.mozilla.org/en-US/docs/Web/HTML/Viewport_meta_tag#viewport_width_and_screen_width
        # this should not exist and no one should ever have to think about it
        meta.viewport = mkOption {
          type = types.submodule ({ ... }: {
            # TODO: figure out how to render only non-default values
            options = {
              width = mkOption {
                type = with types; either
                  (ints.between 1 10000)
                  (enum [ "device-width" ]);
                default = "device-width"; # not default by standard
              };
              height = mkOption {
                type = with types; either
                  (ints.between 1 10000)
                  (enum [ "device-height" ]);
                default = "device-height"; # not default by standard (but seems to work if you don't set it)
              };
              initial-scale = mkOption {
                type = types.numbers.between 0.1 10;
                default = 1;
              };
              minimum-scale = mkOption {
                type = types.numbers.between 0.1 10;
                # TODO: render only as many digits as needed
                default = 0.1;
              };
              maximum-scale = mkOption {
                type = types.numbers.between 0.1 10;
                default = 10;
              };
              user-scalable = mkOption {
                type = types.bool;
                default = true;
              };
              interactive-widget = mkOption {
                type = types.enum [
                  "resizes-visual"
                  "resizes-content"
                  "overlays-content"
                ];
                default = "resizes-visual";
              };
            };
          });
          default = { };
        };

        meta.authors = mkOption {
          type = with types; listOf str;
          default = [ ];
        };
        meta.description = mkOption {
          type = with types; nullOr str;
          default = null;
        };
        link.canonical = mkOption {
          type = with types; nullOr str;
          default = null;
        };

        # TODO: figure out `meta` elements
        # https://html.spec.whatwg.org/multipage/semantics.html#the-meta-element:concept-element-attributes
        # https://html.spec.whatwg.org/multipage/semantics.html#other-metadata-names
      };

      config.categories = [ ];
      config.__toString = self:
        with lib;
        print-element name self.attrs ''
          ${self.title}
          ${with lib; optionalString (!isNull self.base) self.base}
          <meta charset="${self.meta.charset}" />

          ${/* https://html.spec.whatwg.org/multipage/semantics.html#attr-meta-http-equiv-x-ua-compatible */
          ""}<meta http-equiv="X-UA-Compatible" content="IE=edge" />

          <meta name="viewport" content="${join ", " (mapAttrsToList
            (name: value: "${name}=${toString value}") self.meta.viewport)
          }" />

          ${join "\n" (map
              (author: ''<meta name="author" content="${author}" />'')
            self.meta.authors)
          }
        '';
    };

    title = { name, ... }: {
      imports = [ element ];
      options.attrs = mkAttrs { };
      options.text = mkOption {
        type = types.str;
      };
      config.categories = [ "metadata" ];
      config.__toString = self: "<${name}${print-attrs self.attrs}>${self.text}</${name}>";

    };

    base = { name, ... }: {
      imports = [ element ];
      # TODO: "A base element must have either an href attribute, a target attribute, or both."
      options = global-attrs // { inherit (attrs) href target; };
      config.categories = [ "metadata" ];
      config.__toString = self: "<base${print-attrs self}>";
    };

    link = { name, ... }: {
      imports = [ element ];
      options = mkAttrs {
        # TODO: more attributes
        # https://html.spec.whatwg.org/multipage/semantics.html#the-link-element:concept-element-attributes
        inherit (attrs) href;
        # XXX: there are variants of `rel` for `link`, `a`/`area`, and `form`
        rel = mkOption {
          # https://html.spec.whatwg.org/multipage/semantics.html#attr-link-rel
          type = with types; listOfUnique str (enum
            # TODO: work out link types in detail, there are lots of additional constraints
            # https://html.spec.whatwg.org/multipage/links.html#linkTypes
            [
              "alternate"
              "dns-prefetch"
              "expect"
              "help"
              "icon"
              "license"
              "manifest"
              "modulepreload"
              "next"
              "pingback"
              "preconnect"
              "prefetch"
              "preload"
              "prev"
              "privacy-policy"
              "search"
              "stylesheet"
              "terms-of-service"
            ]
          );
        };
      };
      # TODO: figure out how to make body-ok `link` elements
      # https://html.spec.whatwg.org/multipage/semantics.html#allowed-in-the-body
      config.categories = [ "metadata" ];
      config.__toString = self: "<link${print-attrs self}>";
    };

    body = { name, ... }: {
      imports = [ element ];
      options = {
        attrs = mkAttrs { };
        content = mkOption {
          type = with types;
            # HACK: bail out for now
            # TODO: find a reasonable cut-off for where to place raw content
            either str (listOf (attrTag categories.flow));
        };
      };
      config.categories = [ ];
      config.__toString = self: with lib;
        if isList self.content then join "\n" (toString self.content) else self.content;
    };
  };
in
elements
