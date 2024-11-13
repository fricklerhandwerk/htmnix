# Fediversity web site

This web site is built with a static site generator based on the Nix language [module system](https://nix.dev/tutorials/module-system/).
It has unique features such as:
- correct-by-construction relative links, automatic redirects for moved pages
- correct-by-construction content fields
- customisable templating and content structure, all seamlessly expressed in the Nix language
- correct-by-construction spec-compliant HTML output
- content source organisation independent of output structure

Structured content is managed through Nix expressions, and copy is written in [CommonMark](https://commonmark.org/).

# Contributing

- [Install Nix](https://nix.dev/install-nix)
- [Set up `direnv`](https://github.com/nix-community/nix-direnv#installation)
- Run `direnv allow` in the directory where repository is stored on your machine
- Edit any of the files, see [repository layout](#repository-layout) for guidance
- Build and view the web site

  ```bash
  xdg-open $(nix-build -A build --no-out-link)/index.html
  ```

  or

  ```fish
  open (nix-build -A build --no-out-link)/index.html
  ```

# Repository layout

- [content](./content)

  Content of the web site is managed here.
  The entry point is [`content/default.nix`](./content/default.nix) and is built to correspond to `index.html` in the result.
  All other content sources are automatically included in `imports`, and can be accessed though the `config` module argument.

- [structure](./structure)

  Definitions of content data structures, such as pages, articles, menus, collections, etc.

- [presentation](./presentation)

  Code specific to how the web site is rendered.
  In particular, it encodes the mechanism for distributing content to files, and for putting together files for the final result.

  In principle, different output formats (such as RSS feeds) are possible, and would be implemented there.

- [default.nix](./default.nix)

  Entry point for building the project.
  This is where content, structure, and presentation are wired up.

- [shell.nix](./shell.nix)

  Convenience wrapper to enable running `nix-shell` without arguments.

- [lib.nix](./lib.nix)

  Reusable convenience functions.
  Also exposed under the `lib` attribute in [default.nix](./default.nix).

- [npins](./npins)

  Dependencies, managed with [`npins`](https://github.com/andir/npins/).

- [README.md](./README.md)

  This file.
