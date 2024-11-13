{ lib, ... }:
let
  inherit (lib) types;
in
rec {
  collection = elemType:
    let
      unparenthesize = class: class == "noun";
      desc = type:
        types.optionDescriptionPhrase unparenthesize type;
      desc' = type:
        let
          typeDesc = types.optionDescriptionPhrase unparenthesize type;
        in
        if type.descriptionClass == "noun"
        then
          typeDesc + "s"
        else
          "many instances of ${typeDesc}";
    in
    types.mkOptionType {
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
}
