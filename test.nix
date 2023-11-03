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
  testTwoDocuments = {
    expr =
      let
        input = { config, ... }:
          # shorthand module
          {
            config = {
              documents.first.head.title = "first";
              documents.second.head.title = "second";
              documents.second.head.links = [ "hello" "world" ];
            };
          };
        site = renderer.eval [ input ];
      in
      site.config.documents.second.contents;
    expected = ''
      <html>
        <head>
          <title>second</title>
          <link href="hello" rel="canonical">
          <link href="world" rel="canonical">
        </head>
        <body>
        </body>
      </html>
    '';
  };
}
