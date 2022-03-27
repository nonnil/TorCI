import std / [ options ]
# import results

type
  Tab* = ref object
    tab: seq[TabField]

  TabField = ref object
    label: string
    link: string

# method newTab*()

method len*(tab: Tab): int {.base.} =
  tab.tab.len

method isEmpty*(tab: Tab): bool {.base.} =
  tab.len == 0 

proc getLabel*(tab: Tab, i: int): string =
  tab.tab[i].label

proc getLink*(tab: Tab, i: int): string =
  tab.tab[i].link

proc `[]`*(tab: Tab, i: int): Option[TabField] =
  if not tab.tab[i].isNil:
    return some tab.tab[i]

proc getLabel*(tab: TabField): Option[string] =
  if tab.label.len > 0:
    return some tab.label

proc getLink*(tab: TabField): Option[string] =
  if tab.link.len > 0:
    return some tab.link

proc add*(tab: var Tab, label, link: string) =
  let field: TabField = TabField(label: label, link: link)
  tab.tab.add field

proc add*(tab: Tab, label, link: string) =
  let field: TabField = TabField(label: label, link: link)
  tab.tab.add field

iterator items*(tab: Tab): tuple[i: int, label, link: Option[string]] {.inline.} =
  var i: int
  while i < tab.len:
    let f = tab[i]
    if f.isSome:
      yield (i, f.get.getLabel, f.get.getLink)
