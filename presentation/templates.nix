{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  config.templates.html = {
    dom = document:
      let
        eval = lib.evalModules {
          class = "DOM";
          modules = [ document (import ./dom.nix) ];
        };
      in
      {
        __toString = _: toString eval.config;
        value = eval.config;
      };

    markdown = { name, body }:
      let
        commonmark = pkgs.runCommand "${name}.html"
          {
            buildInputs = [ pkgs.cmark ];
          } ''
          cmark ${builtins.toFile "${name}.md" body} > $out
        '';
      in
      builtins.readFile commonmark;
    nav = { menu, page }:
      let
        render-item = item:
          if item ? menu then ''
            <li>${item.menu.label}
              ${lib.indent "  " (item.menu.outputs.html page)}
            </li>
          ''
          else if item ? page then ''<li><a href="${page.link item.page}">${item.page.title}</a></li>''
          else ''<li><a href="${item.link.url}">${item.link.label}</a></li>''
        ;
      in
      ''
        <nav>
          <ul>
            ${with lib; indent "    " (join "\n" (map render-item menu.items))}
          </ul>
        </nav>
      '';
  };
}
