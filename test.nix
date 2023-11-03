let
  renderer = import ./. { };
in
{
  testSimple = {
    expr =
      let
        input = { ... }:
          {
            documents.myDocument.html.head.title = "test hello";
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

  testDefaultTitle = {
    expr =
      let
        input = { ... }:
          {
            documents.myDocument = { };
          };
        site = renderer.eval [ input ];
      in
      site.config.documents.myDocument.out;
    expected = ''
      <html>
        <head>
          <title>myDocument</title>
        </head>
        <body>
        </body>
      </html>
    '';
  };

  testSustomTitle = {
    expr =
      let
        input = { ... }:
          {
            documents.myDocument.title = "foo";
          };
        site = renderer.eval [ input ];
      in
      site.config.documents.myDocument.out;
    expected = ''
      <html>
        <head>
          <title>foo</title>
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
          {
            documents.first = { };
            documents.second.html.head.links = [
              { attrs = { href = "test"; rel = "stylesheet"; }; }
              { attrs = { href = config.documents.first; rel = "canonical"; }; }
            ];
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

  testRedirectTitle = {
    expr =
      let
        input = { config, ... }:
          {
            documents.first.redirects = [ "/redirect.html" ];
            documents.second.html.head.links = [
              { attrs = { href = config.documents.first; rel = "canonical"; }; }
            ];
          };
        site = renderer.eval [ input ];
      in
      site.config.documents.second.out;
    expected = ''
      <html>
        <head>
          <title>second</title>
          <link href="/redirect.html" rel="canonical" />
        </head>
        <body>
        </body>
      </html>
    '';
  };
}
