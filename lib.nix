{ lib }:
rec {
  template =
    g: f: x:
    let
      base = f x;
      result = g base;
    in
    result
    // {
      override =
        new:
        let
          base' =
            if lib.isFunction new then
              lib.recursiveUpdate base (new base' base)
            else
              lib.recursiveUpdate base new;
          result' = g base';
        in
        result'
        // {
          override = new: (template g (x': base') x).override new;
        };
    };

  /**
    Recursively replace occurrences of `from` with `to` within `string`

    Example:

        replaceStringRec "--" "-" "hello-----world"
        => "hello-world"
  */
  replaceStringsRec =
    from: to: string:
    let
      replaced = lib.replaceStrings [ from ] [ to ] string;
    in
    if replaced == string then string else replaceStringsRec from to replaced;

  /**
    Create a URL-safe slug from any string
  */
  slug =
    str:
    let
      # Replace non-alphanumeric characters with hyphens
      replaced = join "" (
        builtins.map (c: if (c >= "a" && c <= "z") || (c >= "0" && c <= "9") then c else "-") (
          with lib; stringToCharacters (toLower str)
        )
      );

      # Remove leading and trailing hyphens
      trimHyphens =
        s:
        let
          matched = builtins.match "(-*)([^-].*[^-]|[^-])(-*)" s;
        in
        with lib;
        optionalString (!isNull matched) (builtins.elemAt matched 1);
    in
    trimHyphens (replaceStringsRec "--" "-" replaced);

  squash = replaceStringsRec "\n\n" "\n";

  /**
    Trim trailing spaces and squash non-leading spaces
  */
  trim =
    string:
    let
      trimLine =
        line:
        with lib;
        let
          # separate leading spaces from the rest
          parts = split "(^ *)" line;
          spaces = head (elemAt parts 1);
          rest = elemAt parts 2;
          # drop trailing spaces
          body = head (split " *$" rest);
        in
        if body == "" then "" else spaces + replaceStringsRec "  " " " body;
    in
    join "\n" (map trimLine (splitLines string));

  join = lib.concatStringsSep;

  splitLines = s: with builtins; filter (x: !isList x) (split "\n" s);

  indent =
    prefix: s:
    with lib.lists;
    let
      lines = splitLines s;
    in
    join "\n" ([ (head lines) ] ++ (map (x: if x == "" then x else "${prefix}${x}") (tail lines)));

  relativePath =
    path1': path2':
    let
      inherit (lib.path) subpath;
      inherit (lib)
        lists
        length
        take
        drop
        min
        max
        ;

      path1 = subpath.components path1';
      prefix1 = take (length path1 - 1) path1;
      path2 = subpath.components path2';
      prefix2 = take (length path2 - 1) path2;

      commonPrefixLength =
        with lists;
        findFirstIndex (i: i.fst != i.snd) (min (length prefix1) (length prefix2)) (
          zipLists prefix1 prefix2
        );

      depth = max 0 (length prefix1 - commonPrefixLength);

      relativeComponents =
        with lists;
        [ "." ] ++ (replicate depth "..") ++ (drop commonPrefixLength path2);
    in
    join "/" relativeComponents;

  /**
      Recursively list all Nix files from a directory, except the top-level `default.nix`

      Useful for module system `imports` from a top-level module.
    *
  */
  nixFiles =
    dir:
    with lib.fileset;
    toList (difference (fileFilter ({ hasExt, ... }: hasExt "nix") dir) (dir + "/default.nix"));

  types = rec {
    # arbitrarily nested attribute set where the leaves are of type `type`
    # NOTE: this works for anything but attribute sets!
    recursiveAttrs =
      type:
      with lib.types;
      # NOTE: due to how `either` works, the first match is significant,
      # so if `type` happens to be an attrset, the typecheck will consider
      # `type`, not `attrsOf`
      attrsOf (either type (recursiveAttrs type));

    # collection of unnamed items that can be added to item-wise, i.e. without wrapping the item in a list
    collection =
      elemType:
      let
        unparenthesize = class: class == "noun";
        desc = type: types.optionDescriptionPhrase unparenthesize type;
        desc' =
          type:
          let
            typeDesc = lib.types.optionDescriptionPhrase unparenthesize type;
          in
          if type.descriptionClass == "noun" then typeDesc + "s" else "many instances of ${typeDesc}";
      in
      lib.types.mkOptionType {
        name = "collection";
        description = "separately specified ${desc elemType} for a collection of ${desc' elemType}";
        merge =
          loc: defs:
          map (
            def:
            elemType.merge (loc ++ [ "[definition ${toString def.file}]" ]) [
              {
                inherit (def) file;
                value = def.value;
              }
            ]
          ) defs;
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

    listOfUnique =
      elemType:
      let
        baseType = lib.types.listOf elemType;
      in
      baseType
      // {
        merge =
          loc: defs:
          let
            # Keep track of which definition each value came from
            defsWithValues = map (
              def:
              map (v: {
                inherit (def) file;
                value = v;
              }) def.value
            ) defs;
            flatDefs = lib.flatten defsWithValues;

            # Check for duplicates while preserving source info
            seen = builtins.foldl' (
              acc: def:
              if lib.lists.any (v: v.value == def.value) acc then
                throw "The option `${lib.options.showOption loc}` has duplicate values (${toString def.value}) defined in ${def.file}"
              else
                acc ++ [ def ]
            ) [ ] flatDefs;
          in
          map (def: def.value) seen;
      };
  };
}
