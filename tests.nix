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
        html.head.title.content = "hello world";
        html.head.meta.x-ua-compat = false;
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
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
        html.head.title.content = "hello world";
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <meta content="IE=edge" http-equiv="X-UA-Compatible">
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
        html.head.title.content = "Character strings considered harmful";
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
      <!DOCTYPE HTML>
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
        html.head.title.content = "Definition lists are best lists";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            dl.content = [
              {
                terms = [ { content = "Definition"; } ];
                descriptions = [ { content = "A boundary of meaning"; } ];
              }
              {
                terms = [
                  { content = "Meaning"; }
                  { content = "Sense"; }
                ];
                descriptions = [
                  { content = "Perception"; }
                  { content = "Thought"; }
                  { content = "Complaint"; }
                ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
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
        html.head.title.content = "Anchors aweigh";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            p.content = [
              {
                a = {
                  attrs.href = "https://example.com";
                  content = "click here";
                };
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
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
        html.head.title.content = "A described page";
        html.head.meta.x-ua-compat = false;
        html.head.meta.description = "A short description";
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
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
        html.head.title.content = "A canonical page";
        html.head.meta.x-ua-compat = false;
        html.head.link.canonical = {
          href = "https://example.com/page";
        };
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
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
  test-base = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Base element";
        html.head.meta.x-ua-compat = false;
        html.head.base = {
          href = "https://example.com";
          target = "_self";
        };
        html.body = { };
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Base element</title>
          <base href="https://example.com" target="_self">
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
  test-details-open = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Details";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            details = {
              attrs.open = true;
              content = [ { p.content = "Where the devil lives"; } ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Details</title>
        </head>
        <body>
          <details open>
            <p>
              Where the devil lives
            </p>
          </details>
        </body>
      </html>
    '';
  };
  test-details-closed = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Details";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            details = {
              summary.content = "Click to find out where the devil lives";
              content = [ { p.content = "In the details"; } ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Details</title>
        </head>
        <body>
          <details>
            <summary>
              Click to find out where the devil lives
            </summary>
            <p>
              In the details
            </p>
          </details>
        </body>
      </html>
    '';
  };
  test-dt-element-content = rec {
    input =
      { ... }:
      {
        html.head.title.content = "dt element content";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            dl.content = [
              {
                terms = [
                  {
                    content = {
                      p.content = "a term";
                    };
                  }
                ];
                descriptions = [ { content = "a description"; } ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>dt element content</title>
        </head>
        <body>
          <dl>
            <dt>
              <p>
                a term
              </p>
            </dt>
            <dd>
              a description
            </dd>
          </dl>
        </body>
      </html>
    '';
  };
  test-div = rec {
    input =
      { ... }:
      {
        html.head.title.content = "div element";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            div.content = [
              { p.content = "inside a div"; }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>div element</title>
        </head>
        <body>
          <div>
            <p>
              inside a div
            </p>
          </div>
        </body>
      </html>
    '';
  };
  test-span = rec {
    input =
      { ... }:
      {
        html.head.title.content = "span element";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            p.content = [
              { span.content = "highlighted text"; }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>span element</title>
        </head>
        <body>
          <p>
            <span>
              highlighted text
            </span>
          </p>
        </body>
      </html>
    '';
  };
  test-code = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Code element";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            p.content = [
              { code.content = "f: let x = f x; in x"; }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Code element</title>
        </head>
        <body>
          <p>
            <code>
              f: let x = f x; in x
            </code>
          </p>
        </body>
      </html>
    '';
  };
  test-unordered-list = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Unordered list";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            ul.content = [
              { content = "first"; }
              { content = "second"; }
              { content = "third"; }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Unordered list</title>
        </head>
        <body>
          <ul>
            <li>
              first
            </li>
            <li>
              second
            </li>
            <li>
              third
            </li>
          </ul>
        </body>
      </html>
    '';
  };
  test-ordered-list = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Ordered list";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            ol = {
              attrs.start = 3;
              attrs.type = "A";
              content = [
                { content = "first"; }
                { content = "second"; }
              ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Ordered list</title>
        </head>
        <body>
          <ol start="3" type="A">
            <li>
              first
            </li>
            <li>
              second
            </li>
          </ol>
        </body>
      </html>
    '';
  };
  test-list-item-flow = rec {
    input =
      { ... }:
      {
        html.head.title.content = "List item with flow content";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            ul.content = [
              {
                content = [
                  { p.content = "a paragraph"; }
                ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>List item with flow content</title>
        </head>
        <body>
          <ul>
            <li>
              <p>
                a paragraph
              </p>
            </li>
          </ul>
        </body>
      </html>
    '';
  };
  test-table-minimal = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Simple table";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table.body = [
              {
                content = [
                  { content = [ { td.content = "cell"; } ]; }
                ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Simple table</title>
        </head>
        <body>
          <table>
            <tr>
              <td>
                cell
              </td>
            </tr>
          </table>
        </body>
      </html>
    '';
  };
  test-table-thead-tbody = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Table with head";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table = {
              head.content = [
                {
                  content = [
                    { th.content = "Name"; }
                    { th.content = "Value"; }
                  ];
                }
              ];
              body = [
                {
                  content = [
                    {
                      content = [
                        { td.content = "foo"; }
                        { td.content = "42"; }
                      ];
                    }
                  ];
                }
              ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Table with head</title>
        </head>
        <body>
          <table>
            <thead>
              <tr>
                <th>
                  Name
                </th>
                <th>
                  Value
                </th>
              </tr>
            </thead>
            <tr>
              <td>
                foo
              </td>
              <td>
                42
              </td>
            </tr>
          </table>
        </body>
      </html>
    '';
  };
  test-table-tbody-attrs = rec {
    input =
      { ... }:
      {
        html.head.title.content = "tbody with attrs";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table.body = [
              {
                attrs = { };
                content = [
                  { content = [ { td.content = "cell"; } ]; }
                ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>tbody with attrs</title>
        </head>
        <body>
          <table>
            <tbody>
              <tr>
                <td>
                  cell
                </td>
              </tr>
            </tbody>
          </table>
        </body>
      </html>
    '';
  };
  test-table-caption = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Table with caption";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table = {
              caption.content = "My Table";
              body = [
                {
                  content = [
                    { content = [ { td.content = "data"; } ]; }
                  ];
                }
              ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Table with caption</title>
        </head>
        <body>
          <table>
            <caption>
              My Table
            </caption>
            <tr>
              <td>
                data
              </td>
            </tr>
          </table>
        </body>
      </html>
    '';
  };
  test-table-tfoot = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Table with foot";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table = {
              body = [
                {
                  content = [
                    { content = [ { td.content = "data"; } ]; }
                  ];
                }
              ];
              foot.content = [
                { content = [ { td.content = "total"; } ]; }
              ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Table with foot</title>
        </head>
        <body>
          <table>
            <tr>
              <td>
                data
              </td>
            </tr>
            <tfoot>
              <tr>
                <td>
                  total
                </td>
              </tr>
            </tfoot>
          </table>
        </body>
      </html>
    '';
  };
  test-table-cell-attrs = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Table cell attributes";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table.body = [
              {
                content = [
                  {
                    content = [
                      { td = { attrs.colspan = 2; content = "wide"; }; }
                    ];
                  }
                  {
                    content = [
                      { td.content = "a"; }
                      { td = { attrs.rowspan = 2; content = "tall"; }; }
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Table cell attributes</title>
        </head>
        <body>
          <table>
            <tr>
              <td colspan="2">
                wide
              </td>
            </tr>
            <tr>
              <td>
                a
              </td>
              <td rowspan="2">
                tall
              </td>
            </tr>
          </table>
        </body>
      </html>
    '';
  };
  test-table-colgroup = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Table with colgroup";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table = {
              colgroups = [
                {
                  content = [
                    { }
                    { span = 2; }
                  ];
                }
              ];
              body = [
                {
                  content = [
                    {
                      content = [
                        { td.content = "a"; }
                        { td.content = "b"; }
                        { td.content = "c"; }
                      ];
                    }
                  ];
                }
              ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Table with colgroup</title>
        </head>
        <body>
          <table>
            <colgroup>
              <col>
              <col span="2">
            </colgroup>
            <tr>
              <td>
                a
              </td>
              <td>
                b
              </td>
              <td>
                c
              </td>
            </tr>
          </table>
        </body>
      </html>
    '';
  };
  test-table-th-scope = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Table with scoped headers";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            table = {
              head.content = [
                {
                  content = [
                    { th = { attrs.scope = "col"; content = "Name"; }; }
                  ];
                }
              ];
              body = [
                {
                  content = [
                    { content = [ { td.content = "Alice"; } ]; }
                  ];
                }
              ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Table with scoped headers</title>
        </head>
        <body>
          <table>
            <thead>
              <tr>
                <th scope="col">
                  Name
                </th>
              </tr>
            </thead>
            <tr>
              <td>
                Alice
              </td>
            </tr>
          </table>
        </body>
      </html>
    '';
  };
  test-code-phrasing = rec {
    input =
      { ... }:
      {
        html.head.title.content = "Code with phrasing content";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          {
            p.content = [
              {
                code.content = [
                  {
                    a = {
                      attrs.href = "https://example.com";
                      content = "example.com";
                    };
                  }
                ];
              }
            ];
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Code with phrasing content</title>
        </head>
        <body>
          <p>
            <code>
              <a href="https://example.com">
                example.com
              </a>
            </code>
          </p>
        </body>
      </html>
    '';
  };
  test-content-coercion = rec {
    input =
      { ... }:
      {
        html.head.title = "Content coercion";
        html.head.meta.x-ua-compat = false;
        html.body.content = [
          { p = "plain paragraph"; }
          {
            p.content = [
              { span = "inline span"; }
              { code = "inline code"; }
              { a = "bare link"; }
            ];
          }
          { ul.content = [ "first" "second" ]; }
          {
            dl.content = [
              {
                terms = [ "a term" ];
                descriptions = [ "a description" ];
              }
            ];
          }
          {
            details = {
              summary = "click to expand";
              content = [ { p = "revealed"; } ];
            };
          }
          {
            table = {
              caption = "my table";
              body = [
                {
                  content = [
                    {
                      content = [
                        { th = "header"; }
                        { td = "cell"; }
                      ];
                    }
                  ];
                }
              ];
            };
          }
        ];
      };
    expr = html input;
    expected = ''
      <!DOCTYPE HTML>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Content coercion</title>
        </head>
        <body>
          <p>
            plain paragraph
          </p>
          <p>
            <span>
              inline span
            </span>
            <code>
              inline code
            </code>
            <a>
              bare link
            </a>
          </p>
          <ul>
            <li>
              first
            </li>
            <li>
              second
            </li>
          </ul>
          <dl>
            <dt>
              a term
            </dt>
            <dd>
              a description
            </dd>
          </dl>
          <details>
            <summary>
              click to expand
            </summary>
            <p>
              revealed
            </p>
          </details>
          <table>
            <caption>
              my table
            </caption>
            <tr>
              <th>
                header
              </th>
              <td>
                cell
              </td>
            </tr>
          </table>
        </body>
      </html>
    '';
  };
}
