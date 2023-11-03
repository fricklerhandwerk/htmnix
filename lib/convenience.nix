# Convenience wrappers for creating sensible DOM more easily
{ lib, ... }:
let
  dom = import ./dom.nix { inherit lib; };
in
rec {
  document = { name, config, ... }: {
    imports = [ dom.document ];
    options.title = lib.mkOption {
      description = "Title of the document to set in `html.head.title`. Defaults to the document's attribute name if not specified.";
      type = with lib.types; nullOr str;
      default = "${name}";
    };
    config.html.head.title = lib.mkOptionDefault config.title;

    options.redirects = with lib; mkOption {
      description = "Historical locations of this document. Prepend new locations to this list.";
      type = with lib.types; listOf path;
      default = [ "/${name}.html" ];
    };
    config.outPath = lib.lists.head config.redirects;
  };
}
