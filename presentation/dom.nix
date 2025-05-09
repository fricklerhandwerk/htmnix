/**
  A strongly typed module system implementation of the Document Object Model (DOM)

  Based on the WHATWG's HTML Living Standard https://html.spec.whatwg.org (CC-BY 4.0)
  Inspired by https://github.com/knupfer/type-of-html by @knupfer (BSD-3-Clause)
  Similar work from the OCaml ecosystem: https://github.com/ocsigen/tyxml
*/
{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  inherit (types) submodule;

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
  element =
    { ... }:
    {
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
  element-types = lib.mapAttrs (_name: value: mkOption { type = submodule value; }) elements;

  # attrset of categories, where values are module options with the type of the
  # elements that belong to these categories
  categories =
    with lib;
    genAttrs content-categories (
      category:
      (mapAttrs (_: e: mkOption { type = submodule e; })
        # HACK: don't evaluate the submodule types, just grab the config directly
        # TODO: we may want to do this properly and loop `categories` through the top-level `config`
        (
          filterAttrs (
            _: e:
            elem category
              (e {
                name = "dummy";
                config = { };
              }).config.categories
          ) elements
        )
      )
    );

  global-attrs = lib.mapAttrs (_name: value: mkOption value) {
    class = {
      type = with types; listOf nonEmptyStr;
      default = [ ];
    };
    hidden = {
      type = types.bool;
      default = false;
    };
    id = {
      # TODO: would be cool if we could enforce unique IDs per document
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

  # all possible attributes to `<link>` elements.
  # since not all of them apply to each `rel=` type, the separate implementations can pick from this collection
  link-attrs = lib.mapAttrs (_name: value: mkOption value) {
    href = {
      # TODO: implement https://html.spec.whatwg.org/multipage/semantics.html#the-link-element:attr-link-href-3
      # TODO: https://url.spec.whatwg.org/#valid-url-string
      type = types.nonEmptyStr;
    };
    media = {
      # TODO: https://drafts.csswg.org/mediaqueries/#media
      #       it's awsome we have that standard, but ugh so much work
      #       ;..S
      #       Clay seems to do it right: https://github.com/sebastiaanvisser/clay
      type = with types; nullOr str;
      default = null;
    };
    integrity = {
      # TODO: implement https://w3c.github.io/webappsec-subresource-integrity/
      type = with types; nullOr str;
      default = null;
    };
    # TODO: more attributes
    #       https://html.spec.whatwg.org/multipage/semantics.html#the-link-element:concept-element-attributes
  };

  # TODO: not sure where to put these, since so far they apply to multiple elements,
  #       but have the same properties for all of them
  attrs = lib.mapAttrs (_name: value: mkOption value) {
    # TODO: investigate: `href` may be coupled with other attributes such as `target` or `hreflang`, this could simplify things
    href = {
      # TODO: https://url.spec.whatwg.org/#valid-url-string
      # ;..O
      type = types.str;
    };
    target = {
      # https://html.spec.whatwg.org/multipage/document-sequences.html#valid-navigable-target-name-or-keyword
      type =
        let
          is-valid-target =
            s:
            let
              inherit (lib) match;
              has-lt = s: match ".*<.*" s != null;
              has-tab-or-newline = s: match ".*[\t\n].*" s != null;
              has-valid-start = s: match "^[^_].*$" s != null;
            in
            has-valid-start s && !(has-lt s && has-tab-or-newline s);
        in
        with types;
        either (enum [
          "_blank"
          "_self"
          "_parent"
          "_top"
        ]) (types.addCheck str is-valid-target);
    };
  };

  mkAttrs =
    attrs:
    with lib;
    mkOption {
      type = submodule {
        options = global-attrs // attrs;
      };
      default = { };
    };

  print-attrs =
    with lib;
    attrs:
    # TODO: figure out how let attributes know how to print themselves without polluting the interface
    let
      result = trim (
        join " " (
          mapAttrsToList
            # TODO: this needs to be smarter for boolean attributes
            #       where the value must be written out explicitly.
            #       probably the attribute itself should have its own `__toString`.
            (
              name: value:
              if isBool value then
                if value then name else ""
              # TODO: some attributes must be explicitly empty
              else
                optionalString (toString value != "") ''${name}="${toString value}"''
            )
            attrs
        )
      );
    in
    if attrs == null then throw "wat" else optionalString (stringLength result > 0) " " + result;

  print-element =
    name: attrs: content:
    with lib;
    # TODO: be smarter about content to save some space and repetition at the call sites
    squash (trim ''
      <${name}${print-attrs attrs}>
        ${lib.indent "  " content}
      </${name}>
    '');

  print-element' = name: attrs: "<${name}${print-attrs attrs}>";

  toString-unwrap =
    e:
    with lib;
    if isAttrs e then
      toString (head (attrValues e))
    else if isList e then
      toString (map toString-unwrap e)
    else
      e;

  elements = rec {
    document =
      { ... }:
      {
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

    html =
      { name, ... }:
      {
        imports = [ element ];
        options = {
          attrs = mkAttrs { };
          inherit (element-types) head body;
        };

        config.categories = [ ];
        config.__toString =
          self:
          print-element name self.attrs ''
            ${self.head}
            ${self.body}
          '';
      };

    head =
      { name, ... }:
      {
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
            type = submodule (
              { ... }:
              {
                # TODO: figure out how to render only non-default values
                options = {
                  width = mkOption {
                    type = with types; either (ints.between 1 10000) (enum [ "device-width" ]);
                    default = "device-width"; # not default by standard
                  };
                  height = mkOption {
                    type = with types; either (ints.between 1 10000) (enum [ "device-height" ]);
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
              }
            );
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
          # TODO: this one has more internal structure, e.g with hreflang
          # TODO: print in output
          link.canonical = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          link.stylesheets = mkOption {
            type = types.listOf (submodule stylesheet);
            default = [ ];
          };

          # TODO: figure out `meta` elements
          # https://html.spec.whatwg.org/multipage/semantics.html#the-meta-element:concept-element-attributes
          # https://html.spec.whatwg.org/multipage/semantics.html#other-metadata-names
        };

        config.categories = [ ];
        config.__toString =
          self:
          with lib;
          print-element name self.attrs ''
            ${self.title}
            ${with lib; optionalString (!isNull self.base) self.base}
            <meta charset="${self.meta.charset}" />

            ${
              # https://html.spec.whatwg.org/multipage/semantics.html#attr-meta-http-equiv-x-ua-compatible
              # TODO: make proper icon and preload types
              ""
            }<meta http-equiv="X-UA-Compatible" content="IE=edge" />
            ${print-element' "meta" {
              name = "viewport";
              content = "${join ", " (
                mapAttrsToList (name: value: "${name}=${toString value}") self.meta.viewport
              )}";
            }}

            ${join "\n" (
              map (
                author:
                print-element' "meta" {
                  name = "author";
                  content = "${author}";
                }
              ) self.meta.authors
            )}

            ${join "\n" (
              map (
                stylesheet:
                print-element' "link" (
                  {
                    rel = "stylesheet";
                  }
                  // (removeAttrs stylesheet [
                    "categories"
                    "__toString"
                  ])
                )
              ) self.link.stylesheets
            )}
          '';
      };

    title =
      { name, ... }:
      {
        imports = [ element ];
        options.attrs = mkAttrs { };
        options.text = mkOption {
          type = types.str;
        };
        config.categories = [ "metadata" ];
        config.__toString = self: "<${name}${print-attrs self.attrs}>${self.text}</${name}>";

      };

    base =
      { ... }:
      {
        imports = [ element ];
        # TODO: "A base element must have either an href attribute, a target attribute, or both."
        options = global-attrs // {
          inherit (attrs) href target;
        };
        config.categories = [ "metadata" ];
        config.__toString = self: "<base${print-attrs self}>";
      };

    link =
      { ... }:
      {
        imports = [ element ];
        options = global-attrs // {
          # TODO: more attributes
          # https://html.spec.whatwg.org/multipage/semantics.html#the-link-element:concept-element-attributes
          inherit (attrs) href;
          # XXX: there are variants of `rel` for `link`, `a`/`area`, and `form`
          rel = mkOption {
            # https://html.spec.whatwg.org/multipage/semantics.html#attr-link-rel
            type =
              with types;
              listOfUnique str (enum
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
                "terms-of-service"
              ]);
          };
        };
        # TODO: figure out how to make body-ok `link` elements
        # https://html.spec.whatwg.org/multipage/semantics.html#allowed-in-the-body
        config.categories = [ "metadata" ];
        config.__toString = self: "<link${print-attrs self}>";
      };

    # <link rel="stylesheet"> is implemented separately because it can be used both in `<head>` and `<body>`
    # semantically it's a standalone thing but syntactically happens to be subsumed under `<link>`
    stylesheet =
      { config, ... }:
      {
        imports = [ element ];
        options = global-attrs // {
          type = mkOption {
            # TODO: this must be a valid MIME type string, which is a bit involved.
            #       the syntax is explicated here: https://mimesniff.spec.whatwg.org/#mime-type-writing
            #       but the spec refers to RFC9110: https://www.rfc-editor.org/rfc/rfc9110#name-media-type
            #       all registered MIME types: https://www.iana.org/assignments/top-level-media-types/top-level-media-types.xhtml
            # XXX: if nothing is specified, "text/css" is assumed.
            #      https://html.spec.whatwg.org/multipage/links.html#link-type-stylesheet:link-type-stylesheet-2
            #      there's no specification on what else could be there, and it's questionable whether setting anything else even makes sense.
            #      in practice, browsers seem to ignore anything but "text/css", so we may as well not care at all.
            type = with types; nullOr str;
            default = null;
          };
          # https://html.spec.whatwg.org/multipage/semantics.html#attr-link-disabled
          disabled = mkOption {
            type = types.bool;
            default = false;
          };
          # TODO: implement the rest of the stylesheet attributes
          #       https://html.spec.whatwg.org/#link-type-stylesheet
          inherit (link-attrs) href media integrity;
        };
        # https://html.spec.whatwg.org/multipage/links.html#link-type-stylesheet:body-ok
        config.categories = [
          "metadata"
          "phrasing"
        ];
        config.__toString =
          self:
          print-attrs (
            removeAttrs self [
              "categories"
              "__toString"
            ]
          );
      };

    body =
      { config, name, ... }:
      {
        imports = [ element ];
        options = {
          attrs = mkAttrs { };
          content = mkOption {
            type =
              with types;
              let
                # Type check that ensures spec-compliant section hierarchy
                # https://html.spec.whatwg.org/multipage/sections.html#headings-and-outlines-2:concept-heading-7
                with-section-constraints =
                  baseType:
                  baseType
                  // {
                    merge =
                      loc: defs:
                      with lib;
                      let
                        find-and-attach =
                          def:
                          let
                            process-with-depth =
                              depth: content:
                              map (
                                x:
                                if isAttrs x && x ? section then
                                  x
                                  // {
                                    section = x.section // {
                                      heading-level = depth;
                                      content = process-with-depth (depth + 1) (x.section.content or [ ]);
                                    };
                                  }
                                else
                                  x
                              ) content;

                            find-with-depth =
                              depth: content:
                              let
                                sections = map (v: {
                                  inherit (def) file;
                                  value = v;
                                  depth = depth;
                                }) (filter (x: isAttrs x && x ? section) content);
                                subsections = concatMap (
                                  x:
                                  if isAttrs x && x ? section && x.section ? content then
                                    find-with-depth (depth + 1) x.section.content
                                  else
                                    [ ]
                                ) content;
                              in
                              sections ++ subsections;

                          in
                          {
                            inherit def;
                            processed = process-with-depth 1 def.value;
                            validation = find-with-depth 1 def.value;
                          };

                        processed = map find-and-attach defs;
                        all-sections = flatten (map (p: p.validation) processed);
                        too-deep = filter (sec: sec.depth > 6) all-sections;
                      in
                      if too-deep != [ ] then
                        throw ''
                          The option `${lib.options.showOption loc}` has sections nested too deeply:
                          ${concatMapStrings (
                            sec: "  - depth ${toString sec.depth} section in ${toString sec.file}\n"
                          ) too-deep}
                          Section hierarchy must not be deeper than 6 levels.''
                      else
                        baseType.merge loc (map (p: p.def // { value = p.processed; }) processed);
                  };
              in
              with-section-constraints
                # TODO: find a reasonable cut-off for where to place raw content
                (listOf (either str (attrTag categories.flow)));
            default = [ ];
          };
        };

        config.categories = [ ];
        config.__toString =
          self: with lib; print-element name self.attrs (join "\n" (map toString-unwrap self.content));
      };

    section =
      { config, name, ... }:
      {
        imports = [ element ];
        options = {
          # setting to an attribute set will wrap the section in `<section>`
          attrs = mkOption {
            type =
              with types;
              nullOr (submodule {
                options = global-attrs;
              });
            default = null;
          };
          heading = mkOption {
            # XXX: while there are no explicit rules on whether sections should contain headers,
            #      sections should have content that would be listed in an outline.
            #
            #      https://html.spec.whatwg.org/multipage/sections.html#use-div-for-wrappers
            #
            #      such an outline is rather meaningless without headings for navigation,
            #      which is why we enforce headings in sections.
            #      arguably, and this is encoded here, a section *is defined* by its heading.
            type =
              with types;
              submodule (
                { config, ... }:
                {
                  imports = [ element ];
                  options = {
                    attrs = mkAttrs { };
                    # setting to an attribute set will wrap the section in `<hgroup>`
                    hgroup.attrs = mkOption {
                      type =
                        with types;
                        nullOr (submodule {
                          options = global-attrs;
                        });
                      default = with lib; if (config.before == [ ] && config.after == [ ]) then null else { };
                    };
                    # https://html.spec.whatwg.org/multipage/sections.html#the-hgroup-element
                    before = mkOption {
                      type = with types; listOf (attrTag ({ inherit (element-types) p; } // categories.scripting));
                      default = [ ];
                    };
                    content = mkOption {
                      # https://html.spec.whatwg.org/multipage/sections.html#the-h1,-h2,-h3,-h4,-h5,-and-h6-elements
                      type = with types; either str (listOf (attrTag categories.phrasing));
                    };
                    after = mkOption {
                      type = with types; listOf (attrTag ({ inherit (element-types) p; } // categories.scripting));
                      default = [ ];
                    };
                  };
                }
              );
          };
          # https://html.spec.whatwg.org/multipage/sections.html#headings-and-outlines
          content = mkOption {
            type = with types; listOf (either str (attrTag categories.flow));
            default = [ ];
          };
        };
        options.heading-level = mkOption {
          # XXX: this will proudly fail if the invariant is violated,
          #      but the error message will be inscrutable
          type = with types; ints.between 1 6;
          internal = true;
        };
        config = {
          categories = [
            "flow"
            "sectioning"
            "palpable"
          ];
          __toString =
            self:
            with lib;
            let
              n = toString config.heading-level;
              heading = ''<h${n}${print-attrs self.heading.attrs}>${self.heading.content}</h${n}>'';
              hgroup =
                with lib;
                print-element "hgroup" self.heading.hgroup.attrs (squash ''
                  ${optionalString (!isNull self.heading.before) (toString-unwrap self.heading.before)}
                  ${heading}
                  ${optionalString (!isNull self.heading.after) (toString-unwrap self.heading.after)}
                '');
              content =
                (if isNull self.heading.hgroup.attrs then heading else hgroup)
                + join "\n" (map toString-unwrap self.content);
            in
            if !isNull self.attrs then print-element name self.attrs content else content;
        };
      };

    p =
      { name, ... }:
      {
        imports = [ element ];
        options = {
          attrs = mkAttrs { };
          content = mkOption {
            type = with types; either str (listOf (attrTag categories.phrasing));
          };
        };
        config.categories = [
          "flow"
          "palpable"
        ];
        config.__toString = self: print-element name self.attrs (toString self.content);
      };

    dl =
      { config, name, ... }:
      {
        imports = [ element ];
        options = {
          attrs = mkAttrs { };
          content = mkOption {
            type =
              with types;
              listOf (
                submodule (
                  { ... }:
                  {
                    options = {
                      # TODO: wrap in `<div>` if set
                      div.attrs = mkOption {
                        type =
                          with types;
                          nullOr (submodule {
                            options = global-attrs;
                          });
                        default = null;
                      };
                      before = mkOption {
                        type = with types; listOf (attrTag categories.scripting);
                        default = [ ];
                      };
                      terms = mkOption {
                        type = with types; nonEmptyListOf (submodule dt);
                      };
                      between = mkOption {
                        type = with types; listOf (attrTag categories.scripting);
                        default = [ ];
                      };
                      descriptions = mkOption {
                        type = with types; nonEmptyListOf (submodule dd);
                      };
                      after = mkOption {
                        type = with types; listOf (attrTag categories.scripting);
                        default = [ ];
                      };
                    };
                  }
                )
              );
          };
        };
        # XXX: here we can't express the spec requirement that `dl` is palpable if the list of term-description-pairs is nonempty.
        #      the reason is that we have to specify a child's *type* in the parent, but being palpable is a property of the value in this case.
        #      and while the module system does have some dependent typing capabilities, we can't say "the type is X but only if its value has property Y".
        #      but since the "palpable" category isn't used in any structural requirement in the spec, this is not a loss of fidelity on our side.
        # TODO: the whole notion of content categories may be a red herring for this implementation after all, reconsider it.
        #       it does help to concisely express type constraints on an element's children, but it seems that most of the categories in the spec can be ignored entirely in this implementation.
        #       the cleanup task would be to identify which categories are really helpful, and document the rationale for using that mechanism as well as the specific choice of categories to keep.
        config.categories = [ "flow" ];
        config.__toString =
          self:
          with lib;
          let
            content = map (
              entry:
              let
                list = squash ''
                  ${join "\n" entry.before}
                  ${join "\n" entry.terms}
                  ${join "\n" entry.between}
                  ${join "\n" entry.descriptions}
                  ${join "\n" entry.after}
                '';
              in
              if !isNull entry.div.attrs then print-element "div" entry.div.attrs list else list
            ) self.content;
          in
          print-element name self.attrs (join "\n" content);
      };

    dt =
      { config, ... }:
      {
        imports = [ element ];
        options = {
          attrs = mkAttrs { };
          dt = mkOption {
            type =
              with types;
              either str (
                submodule (
                  attrTag (
                    # TODO: test
                    with lib;
                    removeAttrs
                      (filterAttrs (
                        _name: value:
                        !any (
                          c:
                          elem c [
                            "sectioning"
                            "heading"
                          ]
                        ) value.categories
                      ) categories.flow)
                      [
                        "header"
                        "footer"
                      ]
                  )
                )
              );
          };
        };
        config.categories = [ ];
        config.__toString = self: print-element "dt" self.attrs self.dt;
      };

    dd =
      { config, ... }:
      {
        imports = [ element ];
        options = {
          attrs = mkAttrs { };
          dd = mkOption {
            type = with types; either str (submodule (attrTag categories.flow));
          };
        };
        config.categories = [ ];
        config.__toString = self: print-element "dd" self.attrs self.dd;
      };
  };
in
{
  imports = [ element ];
  options = {
    inherit (element-types) html;
  };

  config.categories = [ ];
  config.__toString = self: ''
    <!DOCTYPE HTML >
    ${self.html}
  '';
}
