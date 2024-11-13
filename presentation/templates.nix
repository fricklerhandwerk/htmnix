{ lib }:
rec {
  html = { head, body }: ''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        ${lib.indent "    " head}
      </head>
      <body>
        ${lib.indent "    " body}
      <body>
    </html>
  '';
  nav = { page, menu }:
    let
      render-item = item:
        if item ? menu then
          ''
            <li>${item.menu.label}
            ${lib.indent "  " (nav { inherit page; menu = item; })}
          ''
        else
          if item ? page then ''<li><a href="${page.link item.page}">${item.page.title}</a></li>''
          else ''<li><a href="${item.link.url}">${item.link.label}</a></li>''
      ;
    in
    ''
      <nav>
        <ul>
          ${with lib; indent "    " (join "\n" (map render-item menu.menu.items))}
        </ul>
      </nav>
    '';
}
