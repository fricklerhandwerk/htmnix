# HTML elements encoded as modules
{ lib, ... }:
let
  util = import ../util.nix { inherit lib; };
in
rec {
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
      __toString = with lib; mkOption {
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
