# tests written for running with `nix-unit`
# https://github.com/nix-community/nix-unit
let
  inherit (import ./. { }) lib;

  html =
    document:
    let
      eval = lib.evalModules {
        class = "DOM";
        modules = [
          document
          (import ./dom.nix)
        ];
      };
    in
    toString eval.config;
in
{
  test-minimal-dom = rec {
    input =
      { ... }:
      {
        html.head.title.text = "hello world";
        html.head.meta.x-ua-compat = false;
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8">
          <title>hello world</title>
        </head>
        <body>
        </body>
      </html>
    '';
  };
  test-x-ua-compat-default = rec {
    input =
      { ... }:
      {
        html.head.title.text = "hello world";
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          <title>hello world</title>
        </head>
        <body>
        </body>
      </html>
    '';
  };
  test-auto-section = rec {
    input =
      { ... }:
      {
        html.head.title.text = "Character strings considered harmful";
        html.head.meta.x-ua-compat = false;
        html.body = {
          content = [
            {
              section = {
                heading.content = "Why we still use byte soup";
                content = [
                  {
                    p.content = "Dependent types exist but we pretend they don't";
                  }
                  {
                    section = {
                      heading.content = "Breaking news";
                      content = [
                        {
                          p.content = "The module system is very verbose";
                        }
                      ];
                    };
                  }
                ];
              };
            }
            {
              section = {
                heading.content = "The DOM strikes back";
                content = [
                  { p.content = "Standards bring fear"; }
                ];
              };
            }
          ];
        };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8">
          <title>Character strings considered harmful</title>
        </head>
        <body>
          <h1>Why we still use byte soup</h1>
          <p>
            Dependent types exist but we pretend they don't
          </p>
          <h2>Breaking news</h2>
          <p>
            The module system is very verbose
          </p>
          <h1>The DOM strikes back</h1>
          <p>
            Standards bring fear
          </p>
        </body>
      </html>
    '';
  };
  test-definition-lists = rec {
    input =
      { ... }:
      {
        html.head.title.text = "Definition lists are best lists";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            dl.content = [
              {
                terms = [ { dt = "Definition"; } ];
                descriptions = [ { dd = "A boundary of meaning"; } ];
              }
              {
                terms = [
                  { dt = "Meaning"; }
                  { dt = "Sense"; }
                ];
                descriptions = [
                  { dd = "Perception"; }
                  { dd = "Thought"; }
                  { dd = "Complaint"; }
                ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8">
          <title>Definition lists are best lists</title>
        </head>
        <body>
          <dl>
            <dt>
              Definition
            </dt>
            <dd>
              A boundary of meaning
            </dd>
            <dt>
              Meaning
            </dt>
            <dt>
              Sense
            </dt>
            <dd>
              Perception
            </dd>
            <dd>
              Thought
            </dd>
            <dd>
              Complaint
            </dd>
          </dl>
        </body>
      </html>
    '';
  };
  test-anchor = rec {
    input =
      { ... }:
      {
        html.head.title.text = "Anchors aweigh";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            p.content = [
              { a = { attrs.href = "https://example.com"; content = "click here"; }; }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8">
          <title>Anchors aweigh</title>
        </head>
        <body>
          <p>
            <a href="https://example.com">
              click here
            </a>
          </p>
        </body>
      </html>
    '';
  };
  test-meta-description = rec {
    input =
      { ... }:
      {
        html.head.title.text = "A described page";
        html.head.meta.x-ua-compat = false;
        html.head.meta.description = "A short description";
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8">
          <title>A described page</title>
          <meta content="A short description" name="description">
        </head>
        <body>
        </body>
      </html>
    '';
  };
  test-link-canonical = rec {
    input =
      { ... }:
      {
        html.head.title.text = "A canonical page";
        html.head.meta.x-ua-compat = false;
        html.head.link.canonical = "https://example.com/page";
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8">
          <title>A canonical page</title>
          <link href="https://example.com/page" rel="canonical">
        </head>
        <body>
        </body>
      </html>
    '';
  };
  test-relativePath =
    with lib;
    let
      testData = [
        {
          from = "bar";
          to = "baz";
          expected = "./baz";
        }
        {
          from = "foo/bar";
          to = "foo/baz";
          expected = "./baz";
        }
        {
          from = "foo";
          to = "bar/baz";
          expected = "./bar/baz";
        }
        {
          from = "foo/bar";
          to = "baz";
          expected = "./../baz";
        }
        {
          from = "foo/bar/baz";
          to = "foo";
          expected = "./../../foo";
        }
      ];
    in
    {
      expr = map (case: relativePath case.from case.to) testData;
      expected = map (case: case.expected) testData;
    };
}
