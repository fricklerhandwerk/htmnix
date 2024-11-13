{ pkgs, lib, ... }:
rec {
  /**
    Convert a Nix document to HTML
  */
  html = document: name:
    builtins.toFile "${name}.html" ''
      <html>
      <head>
        <title>${document.title}</title>
      </head>
      <body>
      ${builtins.readFile (commonmark document.body name)}
      <body>
      </html>
    '';

  /**
    Convert a commonmark string to HTML
  */
  commonmark = markdown: name:
    pkgs.runCommand "${name}.html" { buildInputs = [ pkgs.cmark ]; } ''
      cmark ${builtins.toFile "${name}.md" markdown} > $out
    '';

  files = dir: lib.mapAttrs'
    (
      attrname: value:
        let
          document = import (dir + "/${attrname}");
          name = lib.removeSuffix ".nix" attrname;
        in
        {
          name = "${name}.html";
          value = html document "${name}.html";
        }
    )
    (builtins.readDir dir);
}
