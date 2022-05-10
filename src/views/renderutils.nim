import std / [ macros, strutils, re ]
import jester
import karax / [ vdom, karaxdsl ]
import ../ routes / tabs
import ".." / [ notice, settings ]

proc getCurrentTab*(r: Request): string =
  const tabs = @[
    (name: "/io", text: "Status"),
    (name: "/net", text: "Network"),
    (name: "/sys", text: "System")
  ]

  for v in tabs:
    if r.pathInfo.startsWith(v.name): return v.text 

proc getNavClass*(path: string; text: string): string = 
  result = "linker"
  if match(path, re("^" & text)):
    result &= " current"

proc icon*(icon: string; text=""; title=""; class=""; href=""): VNode =
  var c = "icon-" & icon
  if class.len > 0: c = c & " " & class
  buildHtml(tdiv(class="icon-container")):
    if href.len > 0:
      a(class=c, title=title, href=href)
    else:
      span(class=c, title=title)

    if text.len > 0:
      text " " & text

const doctype = "<!DOCTYPE html>\n"

proc renderHead(cfg: Config, title: string = ""): VNode =
  buildHtml(head):
    link(rel="stylesheet", `type`="text/css", href="/css/style.css")
    link(rel="stylesheet", type="text/css", href="/css/fontello.css?v=2")
    link(rel="apple-touch-icon", sizes="180x180", href="/apple-touch-icon.png")
    link(rel="icon", type="image/png", sizes="32x32", href="/favicon-32x32.png")
    link(rel="icon", type="image/png", sizes="16x16", href="/favicon-16x16.png")
    link(rel="manifest", href="/site.webmanifest")
    title: 
      if title.len > 0:
        text title & " | " & cfg.title
      else:
        text cfg.title
    meta(name="viewport", content="width=device-width, initial-scale=1.0")

proc renderNav(req: Request; username: string; tab: Tab = new Tab): VNode =
  result = buildHtml(header(class="headers")):
    nav(class="nav-container"):
      tdiv(class="inner-nav"):
        tdiv(class="linker-root"):
          a(class="", href="/"):
            img(class="logo-file", src="/images/torbox.png")
            tdiv(class="service-name"):text cfg.title
        tdiv(class="center-title"):
          text req.getCurrentTab()
        tdiv(class="tabs"):
          a(class=getNavClass(req.pathInfo, "/io"), href="/io"):
            icon "th-large", class="tab-icon"
            tdiv(class="tab-name"):
              text "Status"
          a(class=getNavClass(req.pathInfo, "/net"), href="/net"):
            icon "wifi", class="tab-icon"
            tdiv(class="tab-name"):
              text "Network"
          a(class=getNavClass(req.pathInfo, "/sys"), href="/sys"):
            icon "cog", class="tab-icon"
            tdiv(class="tab-name"):
              text "System"
        tdiv(class="user-drop"):
          icon "user-circle-o"
          input(class="popup-btn", `type`="radio", name="popup-btn", value="open")
          input(class="popout-btn", `type`="radio", name="popup-btn", value="close")
          tdiv(class="dropdown"):
            tdiv(class="panel"):
              tdiv(class="line"):
                icon "user-o"
                tdiv(class="username"): text "Username: " & username
              form(`method`="post", action="/io", enctype="multipart/form-data"):
                button(`type`="submit", name="tor-request", value="restart-tor"):
                  icon "cw"
                  tdiv(class="btn-text"): text "Restart Tor"
              form(`method`="post", action="/logout", enctype="multipart/form-data"):
                button(`type`="submit", name="signout", value="1"):
                  icon "logout"
                  tdiv(class="btn-text"): text "Log out"
        # tdiv(class="logout-button"):
        #   icon "logout"
    if not tab.isEmpty:
      tab.render(req.pathInfo)


proc renderMain*(
  v: VNode;
  req: Request;
  username: string;
  title: string = "",
  tab: Tab = Tab.new();
  notifies: Notifies = Notifies.new()): string =

  let node = buildHtml(html(lang="en")):
    renderHead(cfg, title)

    body:
      if not tab.isEmpty: renderNav(req, username, tab)
      else: renderNav(req, username)

      if not notifies.isEmpty: notifies.render()

      tdiv(class="container"):
        v

  result = doctype & $node

macro render*(title: string, body: untyped): string =
  # expectKind(body.children, nnkCall)
  proc container(n: NimNode): NimNode =
    expectKind(n, { nnkStmtList })
    result = nnkStmtListExpr.newTree()
    let
      # tmp = genSym(nskVar)
      # init = newCall(bindSym"new", ident"VNode")
      call = newCall(
        ident"buildHtml",
        newCall(
          ident"tdiv",
          nnkExprEqExpr.newTree(
            ident"class",
            newLit("cards")
          )
        ),
        n
      )
    echo repr call
    # let x =  tmp.newVarStmt(init)
    # node.add x
    # node.add tmp.newAssignment(call)
    result.add call
    # echo repr result
    # result.add tmp

  # let tmp = genSym(nskVar)
  var node: NimNode = nnkStmtListExpr.newTree()

  for child in body:
    expectKind(child, { nnkCall, nnkCommand, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
    # if child[0].eqIdent("box"):
    expectKind(child[1], { nnkStmtList, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
    node.add newCall(
      bindSym"renderMain",
      container(child[1]),
      ident"request",
      # newDotExpr(ident"request", ident"getUserName"),
      newStrLitNode"Tor-chan",
      title
    )

  node.add
  # echo treeRepr(node)

# macro render*(title: string, body: untyped): string =
#   $(render title.toStrLit: body)