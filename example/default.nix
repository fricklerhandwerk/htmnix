let
  inherit (import ../. { }) build;
in
build {
  pages.index =
    { config, ... }:
    {
      title = "Test";
      description = "A test page";
      summary = "Simply showing off";
      body = ''
        Hello, world!
      '';
    };
}
