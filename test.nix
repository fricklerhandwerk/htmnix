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
              document.myDocument.title = "test hello";
            };
          };
        site = renderer.eval [ input ];
      in
      renderer.renderDocument site.config.document.myDocument;
    expected = "<html>\n<meta>\n  <title>test hello</doc>\n</meta>\n</html>\n";
  };
}
