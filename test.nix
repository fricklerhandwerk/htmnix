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
              documents.myDocument.html.head.title = "test hello";
            };
          };
        site = renderer.eval [ input ];
      in
      site.config.documents.myDocument.out;
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
              documents.first.html.head.title = "first";
              documents.second.html.head.title = "second";
              documents.second.html.head.links = [
                { attrs = { href = "test"; rel = "stylesheet"; }; }
                { attrs = { href = config.documents.first; rel = "canonical"; }; }
              ];
            };
          };
        site = renderer.eval [ input ];
      in
      site.config.documents.second.out;
    expected = ''
      <html>
        <head>
          <title>second</title>
          <link href="test" rel="stylesheet" />
          <link href="/first.html" rel="canonical" />
        </head>
        <body>
        </body>
      </html>
    '';
  };
}
