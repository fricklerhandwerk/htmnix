{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  content-types.document = { name, config, options, link, ... }: {
    config._module.args.link = config.link;
    options = {
      name = mkOption {
        description = "Symbolic name, used as a human-readable identifier";
        type = types.str;
        default = name;
      };
      # TODO: reconsider using `page.outPath` and what to put into `locations`.
      #       maybe we can avoid having ".html" suffixes there.
      #       since templates can output multiple files, `html` is merely one of many things we *could* produce.
      locations = mkOption {
        description = ''
          List of historic output locations for the resulting file

          Elements are relative paths to output files, without suffix.
          The suffix will be added depending on output file type.

          The first element is the canonical location.
          All other elements are used to create redirects to the canonical location.

          The default entry is the symbolic name of the document.
          When changing the symbolic name, append the old one to your custom list and use `lib.mkForce` to make sure the default element will be overridden.
        '';
        type = with types; nonEmptyListOf str;
        apply = config.process-locations;
        example = [ "about/overview" "index" ];
        default = [ config.name ];
      };
      process-locations = mkOption {
        description = "Function to post-process the output locations of contained document";
        type = types.functionTo options.locations.type;
        default = lib.id;
      };
      link = mkOption {
        description = "Helper function for transparent linking to other pages";
        type = with types; functionTo str;
        # TODO: we may want links to other representations,
        #       and currently the mapping of output types to output file
        #       names is soft.
        default = target: with lib; "${relativePath config.outPath target.outPath}.html";
      };
      # TODO: may not need it when using `link`; could repurpose it to render the default template
      outPath = mkOption {
        description = ''
          Location of the page, used for transparently creating links
        '';
        type = types.str;
        default = lib.head config.locations;
      };
      outputs = mkOption {
        description = ''
          Representations of the document in different formats
        '';
        type = with types; attrsOf str;
      };
    };
  };
}
