import std / [ macros ]
import results

macro match*(results: untyped, node: untyped): untyped =
  expectKind results, { nnkCall, nnkIdent }
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
    expectKind child[0], nnkIdent
    expectKind child[1], nnkIdent
    expectKind child[2], nnkStmtList

    let
      resultType = $child[0]
      resultIdent = child[1]
      body = child[2]

    if not resultType.isResultKind(): error "Only \"err\" and \"ok\" are allowed as case labels"
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

    okAssign = quote do:
      let `okIdent` = `getSym`(`tmp`)

    errAssign = quote do:
      let `errIdent` = `errorSym`(`tmp`)

  result = quote do:
    let  `tmp` = `results`
    if `tmp`.isOk:
      `okAssign`
      `okBody`
    
    else:
      `errAssign`
      `errBody`

    


macro withResult*(results: untyped, node: untyped): untyped =
  var
    errCase: NimNode = nil
    okCase: NimNode = nil
    okIdents: NimNode = nil
    errIdents: NimNode = nil

  for resultCase in node:
    # case resultCase.kind:
    # of nnkCall:
    if $resultCase[0] == "err":
        # error "Only \"err\" and \"ok\" are allowed as case labels",
          # resultCase[0]

      if errCase != nil:
        error "Only one \"err\" case is allowed, " &
          "previously defined \"err\" case at: " & lineInfo(errCase),
          resultCase[0]

      else:
        if resultCase[1].kind == nnkBracket:
          if results.kind != nnkBracket:
            error "When only a single result is passed only a single " &
              "identifier must be supplied", resultCase[1]

          for i in resultCase[1]:
            if i.kind != nnkIdent:
              error "List must only contain identifiers", i

        elif results.kind == nnkBracket:
          if $resultCase[1] != "_":
            error "When multiple results are passed all identifiers must be " &
              "supplied", resultCase[1]

        errIdents = if resultCase[1].kind == nnkBracket: resultCase[1] else: newStmtList(resultCase[1])
        errCase = resultCase[2]

    # of nnkCommand:
    if $resultCase[0] == "ok":

      if okCase != nil:
        error "Only one \"ok\" case is allowed, " &
          "previously defined \"ok\" case at: " & lineInfo(okCase),
          resultCase[0]

      else:
        # if resultCase[1].kind != nnkBracket and resultCase[1].kind != nnkIdent:
        #   error "Must have either a list or a single identifier as arguments",
        #     resultCase[1]
        # else:
        if resultCase[1].kind == nnkBracket:
          if results.kind != nnkBracket:
            error "When only a single result is passed only a single " &
              "identifier must be supplied", resultCase[1]

          for i in resultCase[1]:
            if i.kind != nnkIdent:
              error "List must only contain identifiers", i

        elif results.kind == nnkBracket:
          if $resultCase[1] != "_":
            error "When multiple results are passed all identifiers must be " &
              "supplied", resultCase[1]

        okIdents = if resultCase[1].kind == nnkBracket: resultCase[1] else: newStmtList(resultCase[1])
        okCase = resultCase[2]
    # else:
    #   error "Unrecognized structure of cases", resultCase
  if errCase == nil and okCase == nil:
    error "Must have either a \"ok\" case, a \"err\" case, or both"

  var
    body = if okCase != nil: okCase else: nnkDiscardStmt.newTree(newNilLit())
    err = if errCase != nil: errCase else: nnkDiscardStmt.newTree(newNilLit())

  let
    resultsList = (if results.kind == nnkBracket: results else: newStmtList(results))
    getSym = bindSym"get"
    errorSym = bindSym"error"
  
  echo "\"", resultsList.len, "\""

  for i in countdown(resultsList.len - 1, 0):
    let
      ret = resultsList[i]
      tmpLet = genSym(nskLet)
      okIdent = if okIdents.len <= i: newLit("_") else: okIdents[i]
      errIdent = if errIdents.len <= i: newLit("_") else: errIdents[i]
      okAssign = if $okIdent != "_":
        quote do:
          let `okIdent` = `getSym`(`tmpLet`)
      else:
        newStmtList()

      errAssign = if $errIdent != "_":
        quote do:
          let `errIdent` = `errorSym`(`tmpLet`)
      else:
        newStmtList()

    body = quote do:
      let `tmpLet` = `ret`
      if `tmpLet`.isOk:
        `okAssign`
        `body`
      else:
        `errAssign`
        `err`

  result = body