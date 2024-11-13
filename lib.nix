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
    with lib.lists;
    let
      lines = splitLines s;
    in
    join "\n" (
      [ (head lines) ]
      ++
      (map (x: if x == "" then x else "${prefix}${x}") (tail lines))
    );

  relativePath = path1': path2':
    let
      inherit (lib.path) subpath;
      inherit (lib) lists;

      path1 = subpath.components path1';
      prefix1 = with lib; take (length path1 - 1) path1;
      path2 = subpath.components path2';
      prefix2 = with lib; take (length path1 - 1) path2;

      commonPrefixLength = with lists;
        findFirstIndex (i: i.fst != i.snd)
          (length prefix1)
          (zipLists prefix1 prefix2);

      relativeComponents = with lists;
        [ "." ] ++ (replicate (length prefix1 - commonPrefixLength) "..") ++ (drop commonPrefixLength path2);
    in
    join "/" relativeComponents;

  /**
    Recursively list all Nix files from a directory, except the top-level `default.nix`

    Useful for module system `imports` from a top-level module.
  **/
  nixFiles = dir: with lib.fileset;
    toList (difference
      (fileFilter ({ hasExt, ... }: hasExt "nix") dir)
      (dir + "/default.nix")
    );

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
              elemType.merge (loc ++ [ "[definition ${toString def.file}]" ]) [{ inherit (def) file; value = def.value; }]
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

    listOfUnique = elemType:
      let
        baseType = lib.types.listOf elemType;
      in
      baseType // {
        merge = loc: defs:
          let
            # Keep track of which definition each value came from
            defsWithValues = map
              (def:
                map (v: { inherit (def) file; value = v; }) def.value
              )
              defs;
            flatDefs = lib.flatten defsWithValues;

            # Check for duplicates while preserving source info
            seen = builtins.foldl'
              (acc: def:
                if lib.lists.any (v: v.value == def.value) acc
                then throw "The option `${lib.options.showOption loc}` has duplicate values (${toString def.value}) defined in ${def.file}"
                else acc ++ [ def ]
              ) [ ]
              flatDefs;
          in
          map (def: def.value) seen;
      };
  };
}
