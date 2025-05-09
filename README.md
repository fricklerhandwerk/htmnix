# `htmnix`

A HTML rendering engine implemented in the Nix module system.

## Wait, what?

Yes indeed! It's the Document Object Model (DOM) implemented all over again, but with Nix modules.

## But why?

Because we always wanted type-safe, correct-by-construction HTML and relative links, and we always wanted it in the most painful way.

Also because the Nix language intrudes oneself upon us as a templating engine, and is not that bad at it.
A semblance of dependent types, too.

Check [`tests.nix`](./tests.nix) for what one can do with `htmnix`.
Run `nix-shell --run devmode` and try tinkering with the [example](./example/default.nix).

## How do we drive this to its bitter conclusion?

1. [Install Nix](nix.dev/install-nix)
1. Clone this repository:

   ```console
   git clone git@github.com:fricklerhandwerk/htmnix
   ```

1. Set up [direnv](https://github.com/nix-community/nix-direnv#installation)

1. Enable direnv for this repository:

   ```console
   cd htmnix
   direnv allow
   ```

   > **Note**
   >
   > This is a security boundary, and allows automatically running code from this repository on your machine.

1. Edit any of the files, see [repository layout](#repository-layout) for guidance

1. Run the tests:

   ```console
   run-tests
   ```

1. Add more [HTML data structures](https://html.spec.whatwg.org/multipage) to [`//structure`](./structure) and test that they work.

  > **Tip**
  >
  > Run tests in a loop:
  >
  > ```console
  > test-loop
  > ```

## But how to do anything useful with it?

After smashing together old and new code, currently all bets are off in that regard.
But if you feel brave, in order to build a web site, follow this handwavy outline:

- Start a new Nix project.

  You know how to do this, right?

- Somehow get the `devmode` package from this library into your project.

  Probably copy the definition.
  Or open a pull request to expose it in `default.nix` and update this instruction.

- Add a `//content` directory and somehow point this library to it.

  Actually library needs to be slighly reworked for this to be possible, pull requests welcome.
  There are probably some hard design decisions to make it not too painful to work with.

- Start a live preview in a different terminal:

  ```bash
  devmode
  ```

  This will open your default web browser and automatically reload the page when the source changes.

# Repository layout

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

But look, half of it is broken anyway due to a sloppy migration and needs cleanup and proper testing, just ain't nobody got time for that.
Help appreciated.
