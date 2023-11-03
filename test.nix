let
  renderer = import ./. { };
in
{
  testSimple = {
    expr =
      let
        input = { site, ... }:
          # shorthand module
          {
            config = {
              documents.myDocument.head.title = "test hello";
            };
          };
        site = renderer.eval [ input ];
      in
      site.config.documents.myDocument.contents;
    expected = ''
      <html>
        <head>
          <title>test hello</title>
        </head>
        <body>
        </body>
      </html>
    '';
  };
}
