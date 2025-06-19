# `htmnix`

A HTML rendering engine implemented in the Nix module system.

## Wait, what?

Yes indeed! It's the Document Object Model (DOM) implemented all over again, but with Nix modules.

## But why?

Because we always wanted type-safe, correct-by-construction HTML and relative links, and we always wanted it in the most painful way.

Also because the Nix language intrudes oneself upon us as a templating engine, and is not that bad at it.
A semblance of dependent types, too.

Check [`tests.nix`](./tests.nix) for what one can do with `htmnix`.

## How do we drive this to its bitter conclusion?

Help appreciated!

1. [Install Nix](nix.dev/install-nix)
1. Clone this repository:

   ```console
   git clone git@github.com:fricklerhandwerk/htmnix
   ```

1. Run the tests in a loop:

   ```console
   nix-shell --run test-loop
   ```

1. Edit any of the files, see [repository layout](#repository-layout) for guidance

1. Add more [HTML data structures](https://html.spec.whatwg.org/multipage) to [`dom.nix`](./dom.nix) and more tests to verify that they work.

# Repository layout

- [dom.nix](./dom.nix)

  The document object model implemented in the module system.

- [tests.nix](./tests.nix)

  Unit tests for exercising the implementation.

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
