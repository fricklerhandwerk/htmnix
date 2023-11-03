{ config, lib, ... }:
let
  dom = import ./dom.nix { inherit lib; };
  wrap = import ./convenience.nix { inherit lib; };
in
{
  options = with lib; {
    documents = mkOption {
      description = "A Document represents any web page loaded in the browser and serves as an entry point into the web page's content.";
      type = with types; attrsOf (submodule wrap.document);
    };
  };
}
