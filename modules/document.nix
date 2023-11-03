{ config, lib, ... }:
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

  squash = replaceStringsRec "\n\n" "\n";

  splitLines = with lib; s: filter (x: !isList x) (split "\n" s);

  indent = prefix: s:
    let
      lines = splitLines s;
    in
    concatStringsSep "\n" ([ (head lines) ] ++ (map (x: if x == "" then x else "${prefix}${x}") (tail lines)));
in
{
  options = {
    documents = with lib; mkOption {
      description = "a document";
      type = types.attrsOf (types.submodule ({ name, ... }:
        let
          self = config.documents.${name};
        in
        {
          options = {
            contents = with lib; mkOption {
              description = "the document rendered as a string";
              type = types.str;
              default = squash ''
                <html>
                  ${indent "  " self.head.contents}
                  <body>
                  </body>
                </html>
              '';
            };
            head = with lib; mkOption {
              description = "document metadata";
              type = types.submodule {
                options = {
                  contents = with lib; mkOption {
                    description = "the <head> tag rendered as a string";
                    type = types.str;
                    default = ''
                      <head>
                        <title>${self.head.title}</title>
                      </head>
                    '';
                  };
                  title = with lib; mkOption {
                    description = "document title";
                    type = types.str;
                  };
                };
              };
            };
          };
        }));
    };
  };
}
