{ pkgs, lib, ... }:
{
  files = dir: lib.mapAttrs'
    (
      name: value:
        let
          html = "${lib.removeSuffix ".nix" name}.html";
          md = "${lib.removeSuffix ".nix" name}.md";
        in
        {
          name = html;
          value = pkgs.runCommand html { buildInputs = with pkgs; [ cmark ]; } ''
            cmark ${builtins.toFile md (import "${dir}/${name}").body} > $out
          '';
        }
    )
    (builtins.readDir dir);
}
