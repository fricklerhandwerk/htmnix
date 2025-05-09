{ config, lib, ... }:
let
  dom = import ./dom.nix { inherit lib; };
  wrap = import ./convenience.nix { inherit lib; };
in
{
  options = with lib; {
    host = mkOption {
      description = "The web URL under with the site is hosted";
      type = with types; nullOr str;
      example = "https://example.com";
      default = null;
    };
    hostDir = mkOption {
      description = "Subdirectory under which the site is hosted";
      type = with types; nullOr path;
      default = null;
    };
    documents = mkOption {
      description = "A Document represents any web page loaded in the browser and serves as an entry point into the web page's content.";
      type =
        with types;
        attrsOf (
          submodule (
            { name, ... }:
            {
              imports = [ wrap.document ];

              outPath =
                mkIf (config.hostDir != null)
                  "${config.hostDir}${(lib.lists.head config.documents.${name}.redirects)}";
            }
          )
        );
    };
  };
}
