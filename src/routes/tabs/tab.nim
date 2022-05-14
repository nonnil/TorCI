type
  Tab* = ref object
    tab: TabList

  TabList* = seq[TabField]

  TabField* = ref object
    label: string
    link: string

# method newTab*()

method len*(tab: Tab): int {.base.} =
  tab.tab.len

method isEmpty*(tab: Tab): bool {.base.} =
  tab.len == 0 

proc label*(tab: Tab, i: int): string =
  tab.tab[i].label

proc link*(tab: Tab, i: int): string =
  tab.tab[i].link

proc `[]`*(tab: Tab, i: int): TabField =
  # if not tab.tab[i].isNil:
  tab.tab[i]

method label*(self: TabField): string {.base.} =
  self.label

method link*(self: TabField): string {.base.} =
  self.link

proc add*(tab: var Tab, label, link: string) =
  let field: TabField = TabField(label: label, link: link)
  tab.tab.add field

proc add*(tab: Tab, label, link: string) =
  let field: TabField = TabField(label: label, link: link)
  tab.tab.add field

method list*(self: Tab): TabList {.base.} =
  self.tab

# iterator items*(tab: Tab): tuple[i: int, label, link: string] {.inline.} =
#   var i: int
#   while i < tab.len:
#     let f = tab[i]
#     yield (i, f.label, f.link)
