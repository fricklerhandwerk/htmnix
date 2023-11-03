{ config, lib, ... }:
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
            contents = with lib; mkOption {
              description = "the document rendered as a string";
              type = types.str;
              default = ''
                <html>
                <meta>
                  <title>${self.meta.title}</title>
                </meta>
                </html>
              '';
            };
            meta = with lib; mkOption {
              description = "metadata";
              type = types.submodule {
                options = {
                  title = with lib; mkOption {
                    description = "document title";
                    type = types.str;
                  };
                };
              };
            };
          };
        }));
    };
  };
}
