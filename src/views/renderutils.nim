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