{ lib }:
rec {
  nav = menu: page:
    let
      render-item = item:
        if item ? menu then ''
          <li>${item.menu.label}
          ${lib.indent "  " (item.menu.outputs.html page)}
          </li>
        ''
        else if item ? page then ''<li><a href="${page.link item.page}">${item.page.title}</a></li>''
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
