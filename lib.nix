{ pkgs, lib, ... }:
let
  join = lib.concatStringsSep;
in
rec {
  /**
    Build the web site
  */
  site = name: dir:
    let
      script = ''
        mkdir $out
      '' + join "\n" copy;
      copy = lib.mapAttrsToList
        (
          path: document: ''
            mkdir -p $out/$(dirname ${path})
            cp ${document} $out/${path}
          ''
        )
        (files (sources dir));
    in
    pkgs.runCommand name { } script;

  /**
    Get source files from a flat directory
  */
  sources = dir: lib.mapAttrs'
    (
      attrname: value: {
        name = lib.removeSuffix ".nix" attrname;
        value = import (dir + "/${attrname}");
      }
    )
    (builtins.readDir dir);

  /**
    Create a mapping from output file path to document contents
  */
  files = documents: lib.mapAttrs'
    (
      name: document: {
        name = document.outPath;
        value = html document "${name}.html";
      }
    )
    documents;

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
}
