import std / [ macros ]
import results

macro match*(results: untyped, node: untyped): untyped =
  expectKind results, { nnkCall, nnkIdent, nnkCommand }
  expectKind node, nnkStmtList

  type
    ResultKind = enum
      Ok
      Err

  func isResultKind(str: string): bool =
    case str
    of $Ok, $Err:
      true

    else: false

  var
    okIdent, okBody: NimNode
    errIdent, errBody: NimNode
  
  for child in node:
    expectKind child, nnkCall 
    # a case label. expect `Ok` or `Err`.
    expectKind child[0], nnkIdent
    # an ident
    expectKind child[1], nnkIdent
    # a body
    expectKind child[2], nnkStmtList

    let
      resultType = $child[0]
      resultIdent = child[1]
      body = child[2]

    if not resultType.isResultKind(): error "Only \"Err\" and \"Ok\" are allowed as case labels"
    case resultType
    of $Ok:
      okIdent = resultIdent
      okBody = body

    of $Err:
      errIdent = resultIdent
      errBody = body

  let
    tmp = genSym(nskLet)
    getSym = bindSym"get"
    errorSym = bindSym"error"

    # ignore assign if the ident is `_`
    okAssign = if $okIdent == "_": nnkEmpty.newNimNode
               else: quote do:
      let `okIdent` = `getSym`(`tmp`)

    # ignore assign if the ident is `_`
    errAssign = if $errIdent == "_": nnkEmpty.newNimNode
                else: quote do:
      let `errIdent` = `errorSym`(`tmp`)

  result = quote do:
    let `tmp` = `results`
    if `tmp`.isOk:
      `okAssign`
      `okBody`
    
    else:
      `errAssign`
      `errBody`