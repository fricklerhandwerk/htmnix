{
  config,
  lib,
  pkgs,
  ...
}:
{
  # TODO: move all the site-specific assets to examples and tests
  config.assets."fonts.css".path =
    with lib;
    builtins.toFile "fonts.css" (
      join "\n" (
        map
          (font: ''
            @font-face {
              font-family: '${font.name}';
              font-style: normal;
              font-weight: ${toString font.weight};
              src: url(/${head config.assets.${font.file}.locations}) format('woff2');
            }
          '')
          (
            (crossLists (name: file: weight: { inherit name file weight; }) [
              [ "Signika" ]
              [
                "signika-extended.woff2"
                "signika.woff2"
              ]
              [
                500
                700
              ]
            ])
            ++ (crossLists (name: file: weight: { inherit name file weight; }) [
              [ "Heebo" ]
              [
                "heebo-extended.woff2"
                "heebo.woff2"
              ]
              [
                400
                600
              ]
            ])
          )
      )
    );

  # TODO: get directly from https://github.com/google/fonts
  #       and compress with https://github.com/fonttools/fonttools
  config.assets."signika-extended.woff2" = {
    path = pkgs.fetchurl {
      url = "https://fonts.gstatic.com/s/signika/v25/vEFO2_JTCgwQ5ejvMV0Ox_Kg1UwJ0tKfX6bOjM7sfA.woff2";
      hash = "sha256-6xM7cHYlTKNf1b0gpqhPJjwOoZfxx9+u1e4JPYG2lKk=";
      name = "signika-extended.woff2";
    };
  };
  config.assets."signika.woff2" = {
    path = pkgs.fetchurl {
      url = "https://fonts.gstatic.com/s/signika/v25/vEFO2_JTCgwQ5ejvMV0Ox_Kg1UwJ0tKfX6bBjM4.woff2";
      hash = "sha256-Yu0kGT3seb8Qtulu84wvY6nLyPXsRBO/JvTD2BQBtHg=";
      name = "signika.woff2";
    };
  };
  config.assets."heebo-extended.woff2" = {
    path = pkgs.fetchurl {
      url = "https://fonts.gstatic.com/s/heebo/v26/NGS6v5_NC0k9P9H2TbE.woff2";
      hash = "sha256-lk3+fFEqYWbHHGyXkdhKnOOMGS9m5ZbbxQcRQCSlxDE=";
      name = "heebo-extended.woff2";
    };
  };
  config.assets."heebo.woff2" = {
    path = pkgs.fetchurl {
      url = "https://fonts.gstatic.com/s/heebo/v26/NGS6v5_NC0k9P9H4TbFzsQ.woff2";
      hash = "sha256-JWnjYlbcNsg6KCJnRRjECL2HnZGJOBTMtdutWBNza4Q=";
      name = "heebo.woff2";
    };
  };
}
