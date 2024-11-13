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

  types = rec {
    collection = elemType:
      let
        unparenthesize = class: class == "noun";
        desc = type:
          types.optionDescriptionPhrase unparenthesize type;
        desc' = type:
          let
            typeDesc = lib.types.optionDescriptionPhrase unparenthesize type;
          in
          if type.descriptionClass == "noun"
          then
            typeDesc + "s"
          else
            "many instances of ${typeDesc}";
      in
      lib.types.mkOptionType {
        name = "collection";
        description = "separately specified ${desc elemType} for a collection of ${desc' elemType}";
        merge = loc: defs:
          map
            (def:
              let
                merged = lib.mergeDefinitions
                  (loc ++ [ "[definition ${toString def.file}]" ])
                  elemType
                  [{ inherit (def) file; value = def.value; }];
              in
              if merged ? mergedValue then merged.mergedValue else merged.value
            )
            defs;
        check = elemType.check;
        getSubOptions = elemType.getSubOptions;
        getSubModules = elemType.getSubModules;
        substSubModules = m: collection (elemType.substSubModules m);
        functor = (lib.defaultFunctor "collection") // {
          type = collection;
          wrapped = elemType;
          payload = { };
        };
        nestedTypes.elemType = elemType;
      };
  };
}
