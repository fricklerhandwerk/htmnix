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
              documents.myDocument.meta.title = "test hello";
            };
          };
        site = renderer.eval [ input ];
      in
      renderer.renderDocument site.config.documents.myDocument;
    expected = "<html>\n<meta>\n  <title>test hello</title>\n</meta>\n</html>\n";
  };
}
