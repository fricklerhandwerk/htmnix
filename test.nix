# tests written for `nix-unit`
# https://github.com/nix-community/nix-unit
let
  inherit ((import ./. { }).lib) htmnix tags;
in
{
  testSimple = {
    expr =
      let
        input =
          { ... }:
          {
            documents.myDocument.html.head.title = "hello world";
          };
        site = htmnix [ input ];
      in
      site.config.documents.myDocument.out;
    expected = ''
      <html>
        <head>
          <title>hello world</title>
        </head>
        <body>
        </body>
      </html>
    '';
  };

  testDefaultTitle = {
    expr =
      let
        input =
          { ... }:
          {
            documents.myDocument = { };
          };
        site = htmnix [ input ];
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
        input =
          { ... }:
          {
            documents.myDocument.title = "foo";
          };
        site = htmnix [ input ];
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
        input =
          { config, ... }:
          {
            documents.first = { };
            documents.second.html.head.links = [
              {
                attrs = {
                  href = "test";
                  rel = "stylesheet";
                };
              }
              {
                attrs = {
                  href = config.documents.first;
                  rel = "canonical";
                };
              }
            ];
          };
        site = htmnix [ input ];
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
        input =
          { config, ... }:
          {
            documents.first.redirects = [ "/redirect.html" ];
            documents.second.html.head.links = [
              {
                attrs = {
                  href = config.documents.first;
                  rel = "canonical";
                };
              }
            ];
          };
        site = htmnix [ input ];
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

  testHostDir = {
    expr =
      let
        input =
          { config, ... }:
          {
            hostDir = "/foo/bar";
            documents.first = { };
            documents.second.html.head.links = [
              {
                attrs = {
                  href = config.documents.first;
                  rel = "canonical";
                };
              }
            ];
          };
        site = htmnix [ input ];
      in
      site.config.documents.second.out;
    expected = ''
      <html>
        <head>
          <title>second</title>
          <link href="/foo/bar/first.html" rel="canonical" />
        </head>
        <body>
        </body>
      </html>
    '';
  };

  testBody = {
    expr =
      let
        input =
          { ... }:
          {
            documents.myDocument.html.body.children = with tags; [
              "hello"
              (p.plain { } "world")
            ];
          };
        site = htmnix [ input ];
      in
      site.config.documents.myDocument.out;
    expected = ''
      <html>
        <head>
          <title>myDocument</title>
        </head>
        <body>
          hello
          <p>world</p>
        </body>
      </html>
    '';
  };
}
