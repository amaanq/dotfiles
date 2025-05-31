# Nushell Environment Config File
#
# version = "0.104.1"

$env.ENV_CONVERSIONS.PATH = {
  from_string: {|string|
    $string | split row (char esep) | path expand --no-symlink
  }
  to_string: {|value|
    $value | path expand --no-symlink | str join (char esep)
  }
}

def copy []: string -> nothing {
	print --no-newline $"(ansi osc)52;c;($in | encode base64)(ansi st)"
}

def --env mc [path: path]: nothing -> nothing {
  mkdir $path
  cd $path
}

def --env mcg [path: path]: nothing -> nothing {
  mkdir $path
  cd $path
  git init
}

# Show information about a nix package.
def gist [
  # Any attribute of `pkgs`
  pkg_path: string

  # Show all the metadata
  --long (-l)

  # Open the homepage
  --open (-o)
] {
  let pkg = nix eval --offline --json $"nixpkgs#($pkg_path).meta" | from json

  # Probably because the package doesn't exist. Nix would've printed an error.
  if $pkg == null {
    return
  }

  if $long {
    return $pkg
  }

  if $open {
    start $pkg.homepage
    return $pkg.homepage
  }

  $pkg
    | select name? description? homepage?
    | transpose key value
    | where value != null
    | reduce --fold {} { |row, acc| $acc | merge { $row.key: $row.value } }
}

def bin [num: int] {
	$num | format number | get binary
}

def hex [num: int] {
	$num | format number | get lowerhex
}

def oct [num: int] {
	$num | format number | get octal
}

# TODO - Nix this
# atuin init nu --disable-up-arrow | save -f ~/.config/nushell/atuin.nu
