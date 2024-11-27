# tests written for running with `nix-unit`
# https://github.com/nix-community/nix-unit
let
  inherit (import ./. { }) lib;
in
{
  test-relativePath = {
    expr = with lib; relativePath "bar" "baz";
    expected = "./baz";
  };
}
