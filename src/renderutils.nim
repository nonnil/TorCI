import std / [ macros, strutils, re, httpcore ]
import jester, karax / [ karaxdsl, vdom ]
import routes / tabs
import ./ notice, settings
import lib / [ session ]

const doctype = "<!DOCTYPE html>\n"

proc getCurrentTab*(r: Request): string =
  const tabs = @[
    (name: "/io", text: "Status"),
    (name: "/net", text: "Network"),
    (name: "/tor", text: "Tor"),
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
          a(class=getNavClass(req.pathInfo, "/tor"), href="/tor"):
            icon "tor", class="tab-icon"
            tdiv(class="tab-name"):
              text "Tor"
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
    result.add call

  var
    n: NimNode = nnkStmtListExpr.newTree()
    c: NimNode = nil
    t: NimNode = nil
    nc: NimNode = nil

  for child in body:
    expectKind(child, { nnkCall, nnkCommand, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
    case $child[0]
    of "container":
      expectKind(child[1], { nnkStmtList, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
      c = container(child[1])
    of "notice":
      expectKind(child[1], { nnkStmtList, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
      let notice = child[1][0]
      expectKind(notice, { nnkCall, nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
      nc = nnkStmtListExpr.newTree()
      nc.add notice
    of "tab":
      expectKind(child[1], { nnkStmtList, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
      let tab = child[1][0]
      expectKind(tab, { nnkCall, nnkIdent, nnkSym, nnkOpenSymChoice, nnkClosedSymChoice })
      t = nnkStmtListExpr.newTree()
      t.add tab

  if t.isNil: t = newCall(newIdentNode"new", newIdentNode("Tab"))
  if nc.isNil: nc = newCall(ident"default", ident"Notifies")

  n.add newCall(
    ident"renderMain",
    c,
    ident"request",
    # newDotExpr(ident"request", ident"getUserName"),
    newStrLitNode"Tor-chan",
    title,
    t,
    nc
  )
  n

proc renderError*(e: string): VNode =
  buildHtml():
    tdiv(class="content"):
      tdiv(class="panel-container"):
        tdiv(class="logo-container"):
          img(class="logo", src="/images/torbox.png", alt="TorBox")
        tdiv(class="error-panel"):
          span(): text e
          
proc renderClosed*(): VNode =
  buildHtml():
    tdiv(class="warn-panel"):
      icon "attention", class="warn-icon"
      tdiv(class="warn-subject"): text "Sorry..."
      tdiv(class="warn-description"):
        text "This feature is currently closed as it is under development and can cause bugs"

proc renderPanel*(v: VNode): VNode =
  buildHtml(tdiv(class="main-panel")):
    v

proc renderFlat*(v: VNode, title: string = ""): string =
  let ret = buildHtml(html(lang="en")):
    renderHead(cfg, title)
    body:
      v
  result = doctype & $ret

proc renderFlat*(v: VNode, title: string = "", notifies: Notifies): string =
  let ret = buildHtml(html(lang="en")):
    renderHead(cfg, title)
    body:
      notifies.render
      v
  result = doctype & $ret

template loggedIn*(code: HttpCode = Http403, node: untyped) =
  if await request.isLoggedIn:
    node
  else:
    resp code, "", "application/json"

template loggedIn*(code: HttpCode = Http403, con: string = "", node: untyped) =
  if await request.isLoggedIn:
    node
  else:
    resp code, con, "application/json"