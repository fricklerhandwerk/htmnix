{ config, lib, ... }:
let
  util = import ../util.nix { inherit lib; };
  element = import ./element.nix { inherit lib; };
in
{
  options = {
    documents = with lib; mkOption {
      description = "a document";
      type = types.attrsOf (types.submodule ({ name, ... }:
        let
          self = config.documents.${name};
        in
        {
          options = {
            html = with lib; mkOption {
              type = element.html;
              description = "The <html> HTML element represents the root (top-level element) of an HTML document, so it is also referred to as the root element. All other elements must be descendants of this element.";
            };
            redirects = with lib; mkOption {
              description = "Historical locations of this document. Prepend new locations to this list.";
              type = with types; listOf path;
              default = [ "/${name}.html" ];
            };
            outPath = with lib; mkOption {
              internal = true;
              type = types.str;
              default = lib.lists.head self.redirects;
            };
            out = with lib; mkOption {
              type = with types; str;
              default = "${self.html}";
            };
          };
        }));
    };
  };
}
