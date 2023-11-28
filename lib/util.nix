{ lib }:
let
  inherit (builtins)
    concatStringsSep
    filter
    head
    isList
    replaceStrings
    split
    tail
    ;

  replaceStringsRec = from: to: string:
    # recursively replace occurrences of `from` with `to` within `string`
    # example:
    #     replaceStringRec "--" "-" "hello-----world"
    #     => "hello-world"
    let
      replaced = replaceStrings [ from ] [ to ] string;
    in
    if replaced == string then string else replaceStringsRec from to replaced;
in
rec {
  squash = replaceStringsRec "\n\n" "\n";

  splitLines = with lib; s: filter (x: !isList x) (split "\n" s);

  indent = prefix: s:
    let
      lines = splitLines s;
    in
    concatStringsSep "\n" ([ (head lines) ] ++ (map (x: if x == "" then x else "${prefix}${x}") (tail lines)));

  stringCoercible = with lib; mkOptionType {
    name = "path";
    descriptionClass = "noun";
    check = strings.isStringLike;
    merge = options.mergeEqualOption;
  };

  toAttrs = attrs: concatStringsSep " "
    (lib.attrsets.mapAttrsToList (attr: value: ''${attr}="${value}"'') attrs);
}
