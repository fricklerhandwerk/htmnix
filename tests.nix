# tests written for running with `nix-unit`
# https://github.com/nix-community/nix-unit
let
  inherit (import ./. { }) lib;
in
{
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
