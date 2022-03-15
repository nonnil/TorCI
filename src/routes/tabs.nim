import std / [ macros, options, tables, strutils, strformat ]
import karax / [ vdom, karaxdsl ]

type
  Tabs* = ref object
    list: OrderedTableRef[string, Tab]

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

proc add*(tab: Tab, label, link: string) =
  let field: TabField = TabField(label: label, link: link)
  tab.tab.add field

proc newTabs*(): Tabs =
  result = new Tabs
  # initialize table
  result.list = newOrderedTable[string, Tab]()

proc `[]`*(tabs: Tabs, name: string): Tab =
  tabs.list[name]

# proc getOrDefault*(tabs: tabs, key: string): Tab =
proc `[]=`*(tabs: Tabs, attribute: string, tab: Tab) =
  tabs.list[attribute] = tab

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

proc joinPath(node: NimNode): string =
  expectKind(node, nnkInfix)
  let (left, op, right) = node.unpackInfix()
  if eqIdent(op, "/"):
    case left.kind
    of nnkStrLit:
      result = fmt"{left}/{right}"
    of nnkInfix:
      result = fmt"{joinPath(left)}/{right}"
    else: return

# proc createTab*(node: NimNode): Tab =
#   expectKind(node, nnkStmtList)

#   result = new Tab

#   for asgn in node.children:
#     expectKind(asgn, nnkAsgn)
#     expectKind(asgn[0], nnkStrLit)
#     # expectKind(asgn[1], nnkStrLit)
#     # let op = newAssignment(nnkBracketExpr.newTree(ident, asgn[0]), asgn[1])
#     # let right = newAssignment(ident("str"), asgn[1])
#     var right: string
#     case asgn[1].kind
#     of nnkStrLit:
#       right = $asgn[1]

#     of nnkInfix:
#       # right = $newlit(asgn[1])
#       right = joinPath(asgn[1])

#     else:
#       return

#     result.add $asgn[0], right

proc createTab(node: NimNode): NimNode =
  expectKind(node, nnkStmtList)

  # result = new Tab
  result = newTree(nnkStmtListExpr)
  let
    tmp = genSym(nskLet, "tab")
    call = newCall(bindSym"new", ident("Tab"))
  # result = newStmtList(sym, call)
  result.add newTree(nnkStmtList, newLetStmt(tmp, call))
  # result = newTree(nnkStmtList, newLetStmt(tmp, call))

  for asgn in node.children:
    expectKind(asgn, nnkAsgn)
    expectKind(asgn[0], nnkStrLit)
    # expectKind(asgn[1], nnkStrLit)
    # let op = newAssignment(nnkBracketExpr.newTree(ident, asgn[0]), asgn[1])
    # let right = newAssignment(ident("str"), asgn[1])
    var right: string
    case asgn[1].kind
    of nnkStrLit:
      right = $asgn[1]

    of nnkInfix:
      # right = $newlit(asgn[1])
      right = joinPath(asgn[1])

    else:
      return

    # result.add $asgn[0], right
    let command = newCall(bindSym("add"), tmp, asgn[0], newLit(right))
    result.add command
  result.add tmp

proc createTabs*(node: NimNode): NimNode =
  expectKind(node, nnkStmtList)
  # var tabs = new Tabs
  let
    tabsIdent = newIdentNode("tabs")
    newTabs = newCall("newTabs")
  result = newStmtList()
  result.add newVarStmt(tabsIdent, newTabs)
  # result = newTabs
  for asgn in node.children:
    expectKind(asgn, nnkAsgn)
    expectKind(asgn[0], nnkStrLit)
    # tabs["some"] = tab
    if asgn[1].kind == nnkIdent:
      # let op = newAssignment(nnkBracketExpr.newTree(tabsIdent, asgn[0]), asgn[1])
      let op = newAssignment(nnkBracketExpr.newTree(tabsIdent, asgn[0]), asgn[1])
      result.add op

    # tabs[asgn[0]] = Tab:
    #   "some" = "/some"
    elif asgn[1].kind == nnkCall:
      let
        left = asgn[1][0]
        right = asgn[1][1]
      expectKind(right, nnkStmtList)

      if eqIdent(left, "tab"):
        let tab = createTab(right)
        # let op = newAssignment(nnkBracketExpr.newTree(tabsIdent, asgn[0]), newLit(tab))
        # let op = newAssignment(nnkBracketExpr.newTree(result, asgn[0]), newLit(tab))
        let op = newCall(ident("add"), tabsIdent, asgn[0], newLit(tab))
        # result.add op
        result.add op

macro buildTab*(node: untyped): Tab =
  # expectKind(node, nnkStmtList)
  result = createTab(node)


  # result = newStmtList()


  when defined(debugTabs):
    echo repr result

macro buildTabs*(node: untyped): Tabs =
  # expectKind(node, nnkStmtList)
  result = createTabs(node)


  # result = newStmtList()


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