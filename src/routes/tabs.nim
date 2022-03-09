import std / [ macros, options, tables, strutils ]
import karax / [ vdom, karaxdsl ]

type
  Tabs* = ref object
    list: TableRef[string, Tab]

  Tab* = ref object
    tab: seq[TabField]

  TabField = ref object
    label: string
    link: string

method len*(tab: Tab): int {.base.} =
  tab.tab.len

method len*(tabs: Tabs): int {.base.} =
  tabs.list.len

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

proc `[]=`*(tabs: Tabs, path: string, tab: Tab) =
  tabs.list[path] = tab

iterator items*(tab: Tab): tuple[i: int, label, link: Option[string]] {.inline.} =
  var i: int
  while i < tab.len:
    let f = tab[i]
    if f.isSome:
      yield (i, f.get.getLabel, f.get.getLink)

macro tab*(node: NimNode) =
  expectKind(node, nnkStmtList)

  result = newStmtList()

  # var tab = new Tab
  let
    ident = newIdentNode("tab")
    `new` = nnkCommand.newTree(ident("new"), ident("Tab"))

  result.add newVarStmt(ident, `new`)

  for asgn in node.children:
    expectKind(asgn, nnkAsgn)
    if asgn[1].kind == nnkIdent:
      let op = newAssignment(nnkBracketExpr.newTree(ident, asgn[0]), asgn[1])
      result.add op

proc createTab*(node: NimNode): Tab =
  expectKind(node, nnkStmtList)

  result = new Tab

  # var tab = new Tab
  # let
  #   ident = newIdentNode("tab")
  #   `new` = nnkCommand.newTree(ident("new"), ident("Tab"))

  # result.add newVarStmt(ident, `new`)

  for asgn in node.children:
    expectKind(asgn, nnkAsgn)
    expectKind(asgn[0], nnkStrLit)
    # expectKind(asgn[1], nnkStrLit)
    # let op = newAssignment(nnkBracketExpr.newTree(ident, asgn[0]), asgn[1])
    # let right = newAssignment(ident("str"), asgn[1])
    result.add $asgn[0], $asgn[1]

macro tabs*(node: untyped) =
  expectKind(node, nnkStmtList)

  result = newStmtList()

  # var tabs = new Tabs
  let
    tabsIdent = newIdentNode("tabs")
    `new` = nnkCommand.newTree(ident("new"), ident("Tabs"))
  result.add newVarStmt(tabsIdent, `new`)

  for asgn in node.children:
    expectKind(asgn, nnkAsgn)
    expectKind(asgn[0], nnkStrLit)
    # tabs["some"] = tab
    if asgn[1].kind == nnkIdent:
      let op = newAssignment(nnkBracketExpr.newTree(tabsIdent, asgn[0]), asgn[1])
      result.add op

    # tabs[asgn[0]] = Tab:
    #   "some" = "/some"
    elif asgn[1].kind == nnkCall:
      let
        left = asgn[1][0]
        right = asgn[1][1]
      expectKind(right, nnkStmtList)
      if left != ident("tab"): return
      let tab = createTab(right)
      let op = newAssignment(nnkBracketExpr.newTree(tabsIdent, asgn[0]), newLit(tab))
      result.add op
  when defined(debugTabs):
    echo repr result

proc render*(tab: Tab, currentPath: string): VNode =
  buildHtml(tdiv(class="sub-menu")):
    ul(class="menu-table"):
      for i, label, link in tab.items:
        let class = if currentPath.startsWith(link.get): "menu-item current"
                    else: "menu-item"
        li(class=class):
          a(class="menu-link", href=link.get):
            text label.get