{ lib, ... }:
{
  options = {
    document = with lib; mkOption {
      description = "a document";
      type = types.attrsOf (types.submodule {
        options = {
          title = with lib; mkOption {
            type = types.str;
            description = "document title";
          };
        };
      });
    };
  };
}
