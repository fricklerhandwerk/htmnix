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
          (import ./presentation/dom.nix)
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
