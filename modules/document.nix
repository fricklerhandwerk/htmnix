{ config, lib, ... }:
let
  element = import ./element.nix { inherit lib; };
in
{
  options = {
    documents = with lib; mkOption {
      description = "A Document represents any web page loaded in the browser and serves as an entry point into the web page's content.";
      type = types.attrsOf element.document;
    };
  };
}
