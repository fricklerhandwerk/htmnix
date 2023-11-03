# HTML elements encoded as modules
{ lib, ... }:
{
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
