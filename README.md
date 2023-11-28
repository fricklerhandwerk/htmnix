# `htmnix`

A HTML rendering engine implemented in the Nix module system.

## Wait, what?

Yes indeed! It's the Document Object Model (DOM) implemented all over again, but with Nix modules.

## But why?

Because we always wanted type-safe, correct-by-construction HTML, and we always wanted it in the most painful way.

Also because the Nix language intrudes oneself upon us as a templating engine, and is not that bad at it.

Check [`test.nix`](./test.nix) for examples of what one can do with `htmnix`.

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

1. Run the tests:

   ```console
   nix-unit test.nix
   ```

1. Add more [HTML data structures](https://developer.mozilla.org/en-US/docs/Web/HTML) to [`lib/dom.nix`](./lib/dom.nix) and test that they work.

  > **Tip**
  >
  > Run tests in a loop:
  >
  > ```console
  > find . | entr nix-unit test.nix
  > ```

