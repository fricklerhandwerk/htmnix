{ lib }:
rec {
  /**
    Create a URL-safe slug from any string
  */
  slug = str:
    let
      # Replace non-alphanumeric characters with hyphens
      replaced = join ""
        (
          builtins.map
            (c:
              if (c >= "a" && c <= "z") || (c >= "0" && c <= "9")
              then c
              else "-"
            )
            (with lib; stringToCharacters (toLower str)));

      # Remove leading and trailing hyphens
      trimHyphens = s:
        let
          matched = builtins.match "(-*)([^-].*[^-]|[^-])(-*)" s;
        in
        with lib; optionalString (!isNull matched) (builtins.elemAt matched 1);

      collapseHyphens = s:
        let
          result = builtins.replaceStrings [ "--" ] [ "-" ] s;
        in
        if result == s then s else collapseHyphens result;
    in
    trimHyphens (collapseHyphens replaced);

  join = lib.concatStringsSep;

  splitLines = s: with builtins; filter (x: !isList x) (split "\n" s);

  indent = prefix: s:
    join "\n" (map (x: if x == "" then x else "${prefix}${x}") (splitLines s));
}
