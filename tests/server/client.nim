import std / [
  macros, terminal, unittest,
  httpclient, httpcore ,nativesockets, asyncdispatch,
  strformat, strutils, tables,
  os, osproc
]
import jester #validateip
import utils

export httpClient, httpcore, utils

type
  Routes* = ref object
    # : OrderedTableRef[HttpMethod, seq[string]]
    entries: seq[RouteEntry]

  RouteEntry* = ref object
    kind: HttpMethod
    path: string
    data: MultipartData

proc clientStart*(address: string, port: Port, routes: Routes) {.async.} =
  for entry in routes.entries:
    for i in 0..20:
      var
        client: AsyncHttpClient
        res: Future[AsyncResponse]

      let address = if entry.path.startsWith('/'): fmt"http://{address}:{$port}{entry.path}"
        else: fmt"http://{address}:{$port}/{entry.path}"

      case entry.kind
      of HttpGet:
        client = newAsyncHttpClient()
        res = client.get(address)
        styledEcho fgBlue, "[GET] ", fgWhite, address
      
      of HttpPost:
        client = newAsyncHttpClient()
        client.headers = newHttpHeaders({"Content-Type": "multipart/form-data; boundary=boundary"})
        res = client.post(address, multipart = entry.data)
        styledEcho fgBlue, "[POST] ", fgWhite, address
        # styledEcho fgBlue, "[POST] ", fgWhite, $entry.data
      
      else:
        return

      yield res or sleepAsync(4000)

      if not res.finished:
        styledEcho(fgYellow, "Timed out")
        continue

      elif not res.failed:
        let res = await res

        if res.code.is2xx:
          styledEcho fgBlue, "[Status] ", fgWhite, res.status

          let
            body = await res.body
            headers = res.headers

          if headers["Content-Type"] == "text/html;charset=utf-8": 
            styledEcho fgGreen, "[Content-Type] ", fgWhite, headers["Content-Type"]

          else: 
            styledEcho fgGreen, "[Content-Type] ", fgWhite, headers["Content-Type"]
            styledEcho fgGreen, "[Response body] ", fgWhite, body

        elif res.code.is4xx:
          styledEcho fgBlue, "[Status] ", fgRed, res.status
        
        echo ""
        break

      else: echo res.error.msg
      client.close()

proc createPostBody*(node: NimNode): NimNode =
  expectKind(node, { nnkStmtList, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
  expectKind(node[0], { nnkTableConstr, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
  result = newStmtList()
  let
    tmp = genSym(nskVar)
    init = newCall(bindSym"newMultipartData")
  
  result.add newVarStmt(tmp, init)
  result.add newCall(bindSym"add", tmp, nnkTableConstr.newTree(
    nnkExprColonExpr.newTree(
      newStrLitNode("Content-Disposition"),
      newStrLitNode("form-data")
    )
  ))

  for child in node[0]:
    expectKind(child, { nnkExprColonExpr, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
    expectKind(child[0], { nnkStrLit, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
    expectKind(child[1], { nnkStrLit, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })

    let
      tup = nnkTupleConstr.newTree(child[0], child[1])
      entries = nnkPrefix.newTree(ident"@", nnkBracket.newTree(tup))
    result.add newCall(bindSym"add", tmp, entries)
  
  result.add tmp

macro routerTest*(routerName: string, node: untyped): untyped =
  expectKind(node, { nnkStmtList, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
  result = newStmtList()

  let
    routes = genSym(nskLet)
    init = newCall(bindSym"new", ident("Routes"))

  result.add newTree(nnkStmtList, newLetStmt(routes, init))

  for child in node:
    expectKind(child, { nnkCall, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
    # expect httpMethod
    expectKind(child[0], { nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })

    expectKind(child[1], nnkStmtList)

    let
      httpMethod = parseEnum[HttpMethod]($child[0])
      body = child[1]

    case httpMethod
    of HttpGet:
      for path in body:
        expectKind(path, { nnkStrLit, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })

        result.add nnkCommand.newTree(
          bindSym("add"),
          nnkDotExpr.newTree(
            routes,
            ident"entries"
          ),
          nnkObjConstr.newTree(
            newIdentNode("RouteEntry"),
            nnkExprColonExpr.newTree(
              newIdentNode("kind"),
              ident("HttpGet")
            ),
            nnkExprColonExpr.newTree(
              newIdentNode("path"),
              path
            )
          )
        )
        
    of HttpPost:
      for pair in body:
        expectKind(pair, { nnkCall, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
        # a path
        expectKind(pair[0], { nnkStrLit, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
        let
          path = pair[0]
          data = createPostBody(pair[1])

        result.add newCall(
          bindSym("add"),
          nnkDotExpr.newTree(
            routes,
            ident"entries"
          ),
          nnkObjConstr.newTree(
            newIdentNode("RouteEntry"),
            nnkExprColonExpr.newTree(
              newIdentNode("kind"),
              newIdentNode("HttpPost")
            ),
            nnkExprColonExpr.newTree(
              newIdentNode("path"),
              path
            ),
            nnkExprColonExpr.newTree(
              ident("data"),
              data
            )
          )
        )

    else: error("Invalid HttpMethod")

  let
    tmpProcess = genSym(nskLet)
    startProcess = newLetStmt(tmpProcess, newCall(ident("start"), routerName))
    clientStart = newCall(
      bindSym"waitFor",
      newCall(
        bindSym"clientStart",
        newLit("0.0.0.0"),
        newCall(
          ident"Port",
          newIntLitNode(1984)
        ),
        routes
      )
    )

    kill = newCall(ident"kill", tmpProcess)

  result.add startProcess
  result.add clientStart
  result.add kill