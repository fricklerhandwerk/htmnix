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

  /**
    Get documents from a flat directory of files
  */
  documents = dir: lib.mapAttrs'
    (
      attrname: value: {
        name = lib.removeSuffix ".nix" attrname;
        value = import (dir + "/${attrname}");
      }
    )
    (builtins.readDir dir);

  files = dir: lib.mapAttrs'
    (
      name: document: {
        name = document.outPath;
        value = html document "${name}.html";
      }
    )
    (documents dir);
}
