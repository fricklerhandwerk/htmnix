# The Documente Object Model (DOM) encoded as modules
{ lib, ... }:
let
  util = import ../util.nix { inherit lib; };
in
rec {
  document = lib.types.submodule ({ name, config, ... }: {
    options = {
      html = with lib; mkOption {
        type = html;
        description = "The <html> HTML element represents the root (top-level element) of an HTML document, so it is also referred to as the root element. All other elements must be descendants of this element.";
      };
      title = lib.mkOption {
        description = "Title of the document. Defaults to the document's attribute name if not set. This is a convenience wrapper around `html.head.title`.";
        type = with lib.types; nullOr str;
        default = "${name}";
      };
      redirects = with lib; mkOption {
        description = "Historical locations of this document. Prepend new locations to this list.";
        type = with lib.types; listOf path;
        default = [ "/${name}.html" ];
      };
      outPath = with lib; mkOption {
        internal = true;
        type = types.str;
        default = lib.lists.head config.redirects;
      };
      out = with lib; mkOption {
        type = types.str;
        default = "${config.html}";
      };
    };
    config = {
      html.head.title = lib.mkOptionDefault config.title;
    };
  });
  html = with lib; types.submodule {
    options = {
      head = mkOption {
        description = "The <title> HTML element defines the document's title that is shown in a browser's title bar or a page's tab. It only contains text; tags within the element are ignored.";
        type = head;
      };
      __toString = with lib; mkOption {
        type = with types; functionTo str;
        default = self: util.squash ''
          <html>
            ${util.indent "  " "${self.head}"}
            <body>
            </body>
          </html>
        '';
      };
    };
  };
  head = with lib; types.submodule {
    options = {
      title = mkOption {
        description = "The <title> HTML element defines the document's title that is shown in a browser's title bar or a page's tab. It only contains text; tags within the element are ignored.";
        type = types.str;
      };
      links = mkOption {
        type = types.listOf link;
        default = [ ];
      };
      __toString = mkOption {
        type = with types; functionTo str;
        default = self: util.squash ''
          <head>
            <title>${self.title}</title>
          ${concatStringsSep "\n" (map (s: "  ${s}") self.links)}
          </head>
        '';
      };
    };
  };
  link = with lib; types.submodule {
    options = {
      attrs = {
        href = mkOption {
          description = "This attribute specifies the URL of the linked resource.";
          type = with types; nullOr (either path str);
        };
        rel = mkOption {
          description = "This attribute names a relationship of the linked document to the current document.";
          type = with types; nullOr (enum [
            "canonical"
            "stylesheet"
          ]);
        };
      };
      __toString = with lib; mkOption {
        type = with types; functionTo str;
        default = self:
          ''<link ${concatStringsSep " " (lib.attrsets.mapAttrsToList (attr: value: ''${attr}="${value}"'') self.attrs)} />'';
      };
    };
  };
}
