import karax/[vdom, karaxdsl, vstyles]
import re

proc getNavClass*(path: string; text: string): string = 
  result = "linker"
  if match(path, re("^" & text)):
    result &= " active"

proc getSubmenuClass*(path: string; text: string): string =
  echo text
  if match(path, re("^" & text)):
    return "menu-item active"
  else:
    return "menu-item"

proc icon*(icon: string; text=""; title=""; class=""; href=""): VNode =
  var c = "icon-" & icon
  if class.len > 0: c = c & " " & class
  buildHtml(tdiv(class="icon-container")):
    if href.len > 0:
      a(class=c, title=title, href=href)
    else:
      span(class=c, title=title)

    if text.len > 0:
      text " " & text

proc render404*(): VNode =
  buildHtml(tdiv(class="content")):
    tdiv(class="login-header"):
      img(class="logo", src="/images/torbox.png", alt="TorBox")
    tdiv(class="error-panel"):
      span(): text "404 Not Found"