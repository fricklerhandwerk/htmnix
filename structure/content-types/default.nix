{
  config,
  options,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  imports = lib.nixFiles ./.;

  options.content-types = mkOption {
    description = "Content types";
    type = with types; attrsOf deferredModule;
  };
}
