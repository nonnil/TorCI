import std / [ macros, strformat ]
import tab

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

proc createTab(node: NimNode): NimNode =
  expectKind(node, nnkStmtList)

  result = newTree(nnkStmtListExpr)
  let
    tmp = genSym(nskLet, "tab")
    call = newCall(bindSym"new", ident("Tab"))
  # let tmp = new Tab
  result.add newTree(nnkStmtList, newLetStmt(tmp, call))

  for asgn in node.children:
    expectKind(asgn, nnkAsgn)
    expectKind(asgn[0], nnkStrLit)
    # expectKind(asgn[1], nnkStrLit)
    # let op = newAssignment(nnkBracketExpr.newTree(ident, asgn[0]), asgn[1])
    # let right = newAssignment(ident("str"), asgn[1])
    var right: string
    case asgn[1].kind
    of nnkStrLit: right = $asgn[1]
    of nnkInfix: right = joinPath(asgn[1])
    else: return

    # Represent
    # result.add "Tor", "/tor" / "projet"
    let command = newCall(bindSym("add"), tmp, asgn[0], newLit(right))
    result.add command
  # final value
  result.add tmp

macro buildTab*(node: untyped): Tab =
  result = createTab(node)

  when defined(debugTabs):
    echo repr result