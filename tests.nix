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
    {
      __toString = _: toString eval.config;
      value = eval.config;
    };
in
{
  test-minimal-dom = {
    expr =
      let
        input =
          { ... }:
          {
            html.head.title.text = "hello world";
            html.head.meta.x-ua-compat = false;
            html.body = { };
          };
        site = html input;
      in
      toString site;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8" />
          <title>hello world</title>
        </head>
        <body>
        </body>
      </html>
    '';
  };
  test-x-ua-compat-default = {
    expr =
      let
        input =
          { ... }:
          {
            html.head.title.text = "hello world";
            html.body = { };
          };
        site = html input;
      in
      toString site;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8" />
          <meta http-equiv="X-UA-Compatible" content="IE=edge" />
          <title>hello world</title>
        </head>
        <body>
        </body>
      </html>
    '';
  };
  test-auto-section = {
    expr =
      let
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
        site = html input;
      in
      toString site;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8" />
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
  test-definition-lists = {
    expr =
      let
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
        site = html input;
      in
      toString site;
    expected = ''
      <!DOCTYPE HTML >
      <html>
        <head>
          <meta charset="utf-8" />
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
