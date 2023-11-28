# The Document Object Model (DOM) encoded as modules
{ lib, ... }:
let
  util = import ./util.nix { inherit lib; };
in
rec {
  document = { name, config, ... }: {
    options = with lib; {
      html = mkOption {
        type = types.submodule html;
        description = "The <html> HTML element represents the root (top-level element) of an HTML document, so it is also referred to as the root element. All other elements must be descendants of this element.";
      };
      outPath = mkOption {
        internal = true;
        type = types.str;
        default = "/${name}.html";
      };
      out = mkOption {
        type = types.str;
        default = "${config.html}";
      };
    };
  };
  html = { ... }: {
    options = with lib; {
      head = mkOption {
        description = "The <title> HTML element defines the document's title that is shown in a browser's title bar or a page's tab. It only contains text; tags within the element are ignored.";
        type = types.submodule head;
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
  head = { ... }: {
    options = with lib; {
      title = mkOption {
        description = "The <title> HTML element defines the document's title that is shown in a browser's title bar or a page's tab. It only contains text; tags within the element are ignored.";
        type = types.str;
      };
      links = mkOption {
        type = with types; listOf (submodule link);
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
  link = { ... }: {
    options = with lib; {
      attrs = {
        href = mkOption {
          description = "This attribute specifies the URL of the linked resource.";
          type = with types; nullOr util.stringCoercible;
        };
        rel = mkOption {
          description = "This attribute names a relationship of the linked document to the current document.";
          type = with types; nullOr (enum [
            "canonical"
            "stylesheet"
          ]);
        };
      };
      __toString = mkOption {
        type = with types; functionTo str;
        default = self:
          ''<link ${util.toAttrs self.attrs} />'';
      };
    };
  };
}
