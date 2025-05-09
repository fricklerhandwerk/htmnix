{
  config,
  lib,
  pkgs,
  ...
}:

{
  config.templates.html = {
    dom =
      document:
      let
        eval = lib.evalModules {
          class = "DOM";
          modules = [
            document
            (import ./dom.nix)
          ];
        };
      in
      {
        __toString = _: toString eval.config;
        value = eval.config;
      };

    markdown =
      { name, body }:
      let
        commonmark =
          pkgs.runCommand "${name}.html"
            {
              buildInputs = [ pkgs.cmark ];
            }
            ''
              cmark ${builtins.toFile "${name}.md" body} > $out
            '';
      in
      builtins.readFile commonmark;

    nav =
      { menu, page }:
      let
        # TODO: this is simply printing a tree with a certain template, make that explicit
        render-item =
          item:
          if item ? menu then
            ''
              <li><details><summary>${item.menu.label}</summary>
                ${lib.indent "  " (item.menu.outputs.html page)}
              </li>
            ''
          else if item ? page then
            ''<li><a href="${page.link item.page}">${item.page.title}</a></li>''
          else
            ''<li><a href="${item.link.url}">${item.link.label}</a></li>'';
      in
      ''
        <nav>
          <ul>
            ${with lib; indent "    " (join "\n" (map render-item menu.items))}
          </ul>
        </nav>
      '';
  };

  config.templates.files =
    fs:
    with lib;
    foldl'
      # TODO: create static redirects from `tail <collection>.locations`
      (
        acc: elem:
        acc
        //
          (mapAttrs' (
            type: value: {
              name = head elem.locations + optionalString (type != "") ".${type}";
              value =
                if isStorePath value then
                  value
                else
                  builtins.toFile (elem.name + optionalString (type != "") ".${type}") (toString value);
            }
          ))
            elem.outputs
      )
      { }
      fs;
}
