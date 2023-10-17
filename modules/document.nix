{ lib, ... }:
{
  options = {
    documents = with lib; mkOption {
      description = "a document";
      type = types.attrsOf (types.submodule {
        options = {
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
      });
    };
  };
}
