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
            outPath = with lib; mkOption {
              type = types.str;
              description = "the relative path of this document within the site";
              internal = true;
              default = head config.documents.${name}.redirects;
            };
            contents = with lib; mkOption {
              description = "the document rendered as a string";
              type = types.str;
              default = util.squash ''
                <html>
                  ${util.indent "  " "${self.head}"}
                  <body>
                  </body>
                </html>
              '';
            };
            redirects = with lib; mkOption {
              description = "historical locations of this document";
              type = with types; listOf path;
              default = [ "/${name}.html" ];
            };
            head = with lib; mkOption {
              description = "The <title> HTML element defines the document's title that is shown in a browser's title bar or a page's tab. It only contains text; tags within the element are ignored.";
              type = element.head;
            };
          };
        }));
    };
  };
}
