_: self: _:
let
  inherit (self) merge mkMerge;
in
{
  # When the block has a `_type` attribute in the NixOS
  # module system, anything not immediately relevant is
  # silently ignored. We can make use of that by adding
  # a `__functor` attribute, which lets us call the set.
  merge = mkMerge [ ] // {
    __functor =
      self: next:
      self
      // {
        # Technically, `contents` is implementation defined
        # but nothing ever happens, so we can rely on this.
        contents = self.contents ++ [ next ];
      };
  };

  enabled = merge { enable = true; };
  disabled = merge { enable = false; };

  stringToPort =
    str:
    let
      inherit (self) strings lists;
      chars = map strings.charToInt (strings.stringToCharacters str);
      hash = (lists.foldl builtins.bitXor 0 chars) * 257;
      port = hash - (hash / 64000) * 64000;
    in
    port + 1024;
}
