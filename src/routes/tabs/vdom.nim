import std / [ options, strutils ]
import karax / [ karaxdsl, vdom ]
import tab

proc render*(tab: Tab, currentPath: string): VNode =
  buildHtml(tdiv(class="sub-menu")):
    ul(class="menu-table"):
      for i, label, link in tab.items:
        let class = if currentPath.startsWith(link.get): "menu-item current"
                    else: "menu-item"
        li(class=class):
          a(class="menu-link", href=link.get):
            text label.get