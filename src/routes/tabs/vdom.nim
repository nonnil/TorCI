import std / [ strutils ]
import karax / [ karaxdsl, vdom ]
import tab

func render*(self: Tab, currentPath: string): VNode =
  buildHtml(tdiv(class="sub-menu")):
    ul(class="menu-table"):
      for i, v in self.list:
        let class = if currentPath.startsWith(v.link): "menu-item current"
                    else: "menu-item"
        li(class=class):
          a(class="menu-link", href=v.link):
            text v.label