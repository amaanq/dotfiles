_: self: _:
let
  inherit (self) filter hasSuffix;
  inherit (self.filesystem) listFilesRecursive;
in
{
  collectNix = path: listFilesRecursive path |> filter (hasSuffix ".nix");
}
