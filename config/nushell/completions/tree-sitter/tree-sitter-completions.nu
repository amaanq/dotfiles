module completions {

  # Generates and tests parsers
  export extern tree-sitter [
    --help(-h)                # Print help
    --version(-V)             # Print version
  ]

  # Generate a default config file
  export extern "tree-sitter init-config" [
    --help(-h)                # Print help
  ]

  # Initialize a grammar repository
  export extern "tree-sitter init" [
    --update(-u)              # Update outdated files
    --help(-h)                # Print help
  ]

  # Generate a parser
  export extern "tree-sitter generate" [
    grammar_path?: string     # The path to the grammar file
    --log(-l)                 # Show debug log during generation
    --no-bindings             # Deprecated (no-op)
    --abi: string             # Select the language ABI version to generate (default 15). Use --abi=latest to generate the newest supported version (15).
    --build(-b)               # Compile all defined languages in the current dir
    --debug-build(-0)         # Compile a parser in debug mode
    --libdir: string          # The path to the directory containing the parser library
    --output(-o): string      # The path to output the generated source files
    --report-states-for-rule: string # Produce a report of the states for the given rule, use `-` to report every rule
    --js-runtime: string      # The name or path of the JavaScript runtime to use for generating parsers
    --help(-h)                # Print help
  ]

  # Compile a parser
  export extern "tree-sitter build" [
    --wasm(-w)                # Build a WASM module instead of a dynamic library
    --docker(-d)              # Run emscripten via docker even if it is installed locally (only if building a WASM module with --wasm)
    --output(-o): string      # The path to output the compiled file
    path?: string             # The path to the grammar directory
    --reuse-allocator         # Make the parser reuse the same allocator as the library
    --debug(-0)               # Compile a parser in debug mode
    --help(-h)                # Print help
  ]

  def "nu-complete tree-sitter parse encoding" [] {
    [ "utf8" "utf16-le" "utf16-be" ]
  }

  # Parse files
  export extern "tree-sitter parse" [
    --paths: string           # The path to a file with paths to source file(s)
    ...paths: string          # The source file(s) to use
    --scope: string           # Select a language by the scope instead of a file extension
    --debug(-d)               # Show parsing debug log
    --debug-build(-0)         # Compile a parser in debug mode
    --debug-graph(-D)         # Produce the log.html file with debug graphs
    --wasm                    # Compile parsers to wasm instead of native dynamic libraries
    --dot                     # Output the parse data with graphviz dot
    --xml(-x)                 # Output the parse data in XML format
    --cst(-c)                 # Output the parse data in a pretty-printed CST format
    --stat(-s)                # Show parsing statistic
    --timeout: string         # Interrupt the parsing process by timeout (µs)
    --time(-t)                # Measure execution time
    --quiet(-q)               # Suppress main output
    --edits: string           # Apply edits in the format: "row, col delcount insert_text"
    --encoding: string@"nu-complete tree-sitter parse encoding" # The encoding of the input files
    --open-log                # Open `log.html` in the default browser, if `--debug-graph` is supplied
    --config-path: string     # The path to an alternative config.json file
    --test-number(-n): string # Parse the contents of a specific test
    --rebuild(-r)             # Force rebuild the parser
    --no-ranges               # Omit ranges in the output
    --help(-h)                # Print help
  ]

  # Run a parser's tests
  export extern "tree-sitter test" [
    --include(-i): string     # Only run corpus test cases whose name matches the given regex
    --exclude(-e): string     # Only run corpus test cases whose name does not match the given regex
    --update(-u)              # Update all syntax trees in corpus files with current parser output
    --debug(-d)               # Show parsing debug log
    --debug-build(-0)         # Compile a parser in debug mode
    --debug-graph(-D)         # Produce the log.html file with debug graphs
    --wasm                    # Compile parsers to wasm instead of native dynamic libraries
    --open-log                # Open `log.html` in the default browser, if `--debug-graph` is supplied
    --config-path: string     # The path to an alternative config.json file
    --show-fields             # Force showing fields in test diffs
    --rebuild(-r)             # Force rebuild the parser
    --overview-only           # Show only the pass-fail overview tree
    --help(-h)                # Print help
  ]

  # Increment the version of a grammar
  export extern "tree-sitter version" [
    version: string           # The version to bump to
    --help(-h)                # Print help
  ]

  # Fuzz a parser
  export extern "tree-sitter fuzz" [
    --skip(-s): string        # List of test names to skip
    --subdir: string          # Subdirectory to the language
    --edits: string           # Maximum number of edits to perform per fuzz test
    --iterations: string      # Number of fuzzing iterations to run per test
    --include(-i): string     # Only fuzz corpus test cases whose name matches the given regex
    --exclude(-e): string     # Only fuzz corpus test cases whose name does not match the given regex
    --log-graphs              # Enable logging of graphs and input
    --log(-l)                 # Enable parser logging
    --rebuild(-r)             # Force rebuild the parser
    --help(-h)                # Print help
  ]

  # Search files using a syntax tree query
  export extern "tree-sitter query" [
    query_path: string        # Path to a file with queries
    --time(-t)                # Measure execution time
    --quiet(-q)               # Suppress main output
    --paths: string           # The path to a file with paths to source file(s)
    ...paths: string          # The source file(s) to use
    --byte-range: string      # The range of byte offsets in which the query will be executed
    --row-range: string       # The range of rows in which the query will be executed
    --scope: string           # Select a language by the scope instead of a file extension
    --captures(-c)            # Order by captures instead of matches
    --test                    # Whether to run query tests or not
    --config-path: string     # The path to an alternative config.json file
    --help(-h)                # Print help
  ]

  # Highlight a file
  export extern "tree-sitter highlight" [
    --html(-H)                # Generate highlighting as an HTML document
    --css-classes             # When generating HTML, use css classes rather than inline styles
    --check                   # Check that highlighting captures conform strictly to standards
    --captures-path: string   # The path to a file with captures
    --query-paths: string     # The paths to files with queries
    --scope: string           # Select a language by the scope instead of a file extension
    --time(-t)                # Measure execution time
    --quiet(-q)               # Suppress main output
    --paths: string           # The path to a file with paths to source file(s)
    ...paths: string          # The source file(s) to use
    --config-path: string     # The path to an alternative config.json file
    --help(-h)                # Print help
  ]

  # Generate a list of tags
  export extern "tree-sitter tags" [
    --scope: string           # Select a language by the scope instead of a file extension
    --time(-t)                # Measure execution time
    --quiet(-q)               # Suppress main output
    --paths: string           # The path to a file with paths to source file(s)
    ...paths: string          # The source file(s) to use
    --config-path: string     # The path to an alternative config.json file
    --help(-h)                # Print help
  ]

  # Start local playground for a parser in the browser
  export extern "tree-sitter playground" [
    --quiet(-q)               # Don't open in default browser
    --grammar-path: string    # Path to the directory containing the grammar and wasm files
    --help(-h)                # Print help
  ]

  # Print info about all known language parsers
  export extern "tree-sitter dump-languages" [
    --config-path: string     # The path to an alternative config.json file
    --help(-h)                # Print help
  ]

  def "nu-complete tree-sitter complete shell" [] {
    [ "bash" "elvish" "fish" "power-shell" "zsh" "nushell" ]
  }

  # Generate shell completions
  export extern "tree-sitter complete" [
    --shell(-s): string@"nu-complete tree-sitter complete shell" # The shell to generate completions for
    --help(-h)                # Print help
  ]

}

export use completions *
