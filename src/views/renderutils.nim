import jester
import karax/[vdom, karaxdsl, vstyles]
import strutils, re

proc getCurrentTab*(r: Request): string =
  const tabs = @[
    (name: "/io", text: "Status"),
    (name: "/net", text: "Network"),
    (name: "/sys", text: "System")
  ]
  for v in tabs:
    if r.pathInfo.startsWith(v.name): return v.text 

proc getNavClass*(path: string; text: string): string = 
  result = "linker"
  if match(path, re("^" & text)):
    result &= " current"

proc getSubmenuClass*(path: string; text: string): string =
  echo text
  if match(path, re("^" & text)):
    return "menu-item current"
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