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
      site.config.documents.myDocument.contents;
    expected = ''
      <html>
      <meta>
        <title>test hello</title>
      </meta>
      </html>
    '';
  };
}
