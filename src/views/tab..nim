import std / [ options ]
import results

type
  Tab* = ref object
    tab: seq[TabField]

  TabField = ref object
    label: string
    link: string

# method text*(tab: Tab): string {.compileTime.} =
#   tab.tab.text

method len*(tab: Tab): int {.base, compileTime.} =
  tab.tab.len

proc getLabel*(tab: Tab, i: int): string {.compileTime.} =
  tab.tab[i].label

proc getLink*(tab: Tab, i: int): string {.compileTime.} =
  tab.tab[i].link

proc `[]`*(tab: Tab, i: int): Option[TabField] {.compileTime.} =
  if not tab.tab[i].isNil:
    return some tab.tab[i]

proc getLabel*(tab: TabField): Option[string] {.compileTime.} =
  if tab.label.len > 0:
    return some tab.label

proc getLink*(tab: TabField): Option[string] {.compileTime.} =
  if tab.link.len > 0:
    return some tab.link

proc add*(tab: var Tab, label, link: string): Result[bool, string] {.compileTime.} =
  let field: TabField = TabField(label: label, link: link)
  tab.tab.add field

iterator items*(tab: Tab): tuple[i: int, label, link: Option[string]] {.inline.} =
  var i: int
  while i < tab.len:
    let f = tab[i]
    if f.isSome:
      yield (i, f.get.getLabel, f.get.getLink)