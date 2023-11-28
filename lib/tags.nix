# Helpers for creating valid DOM
{
  p.raw = attrs: children: { inherit attrs children; };
  p.plain = attrs: text: {
    inherit attrs;
    children = [ text ];
  };
}
