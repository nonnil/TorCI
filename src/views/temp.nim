import karax/[karaxdsl, vdom, vstyles]
import jester
import renderutils
import ".."/types
# import re, os

const
  doctype = "<!DOCTYPE html>\n"
  colourGreen = "#2ECC71"
  colourYellow = ""
  colourGray = "#afafaf"
  colourRed = "#E74C3C"
  
proc renderHead(cfg: Config): VNode =
  buildHtml(head):
    link(rel="stylesheet", `type`="text/css", href="/css/style.css")
    link(rel="stylesheet", type="text/css", href="/css/fontello.css?v=2")
    title: 
      text cfg.title
    meta(name="viewport", content="width=device-width, initial-scale=1.0")


proc renderSubMenu*(req: Request; menu: Menu): VNode =
  buildHtml(tdiv(class="sub-menu")):
    ul(class="menu-table"):
      for i, v in menu.text:
        li(class=getSubmenuClass(req.pathInfo, menu.anker[i])):
          #echo links.high
          if menu.anker.high < i:
            a(class="menu-link"):
              text v
          else:
            a(class="menu-link", href=menu.anker[i]):
              text v

proc renderNav(cfg: Config; req: Request; username: string; menu = Menu()): VNode =
  result = buildHtml(header(class="headers")):
    nav(class="nav-container"):
      a(class="linker-root", href="/"):
        img(class="logo-file", src="/images/torbox.png")
        tdiv(class="service-name"):text cfg.title
      tdiv(class="controle"):
        a(class=getNavClass(req.pathInfo, "/io"), href="/io"): text "Status"
        a(class=getNavClass(req.pathInfo, "/net"), href="/net"): text "Network"
        # a(class=getNavClass(req.pathInfo, "/confs"), href="/confs"): text "Configurations"
        # a(class=getNavClass(req.pathInfo, "/docs"), href="/docs"): text "Documents"
        a(class=getNavClass(req.pathInfo, "/sys"), href="/sys"): text "System"
      tdiv(class="user-drop"):
        tdiv(class="user-status"):
          icon "user-circle"
          tdiv(class="username"): text username
          icon "down-open"
        tdiv(class="dropdown"):
          tdiv(class="panel"):
            form(`method`="post", action="/logout", enctype="multipart/form-data"):
              button(`type`="submit", name="signout", value="1"):
                icon "logout"
                tdiv(class="logout-text"): text "Log out"
        # tdiv(class="logout-button"):
        #   icon "logout"
    if menu.text.len != 0:
      renderSubMenu(req, menu)

proc renderError*(e: string): VNode =
  buildHtml():
    tdiv(class="content"):
      tdiv(class="panel-container"):
        tdiv(class="logo-container"):
          img(class="logo", src="/images/torbox.png", alt="TorBox")
        tdiv(class="error-panel"):
          span(): text e
          
proc renderClose*(): VNode =
  buildHtml():
    tdiv(class="warn-panel"):
      icon "attention", class="warn-icon"
      tdiv(class="warn-subject"): text "Sorry..."
      tdiv(class="warn-description"):
        text "This feature is currently closed as it is under development and can cause bugs"

proc renderPanel*(v: VNode): VNode =
  buildHtml(tdiv(class="main-panel")):
    v

proc renderContainer*(v: VNode): VNode =
  buildHtml(tdiv(class="container-inside")):
    tdiv(class="container-inside")
    renderPanel(v)

proc renderNode*(v: VNode; req: Request; cfg: Config; username: string; menu = Menu()): string =
  let node = buildHtml(html(lang="en")):
    renderHead(cfg)
    body:
      if menu.text.len != 0:
        renderNav(cfg, req, username, menu)
      else:
        renderNav(cfg, req, username)
      tdiv(class="container"):
        v
  result = doctype & $node

proc renderNode*(v: VNode; req: Request; cfg: Config; username: string; menu = Menu(); notice: Notice): string =
  let node = buildHtml(html(lang="en")):
    renderHead(cfg)
    body:
      if menu.text.len != 0:
        renderNav(cfg, req, username, menu)
      else:
        renderNav(cfg, req, username)
      if notice.msg.len > 0:
        let colour =
          case notice.status
          of success:
            colourGreen

          of warn:
            colourYellow

          of failure:
            colourRed

          else:
            colourGray

        tdiv(class="notice-bar"):
          input(id="ignoreNotice", `type`="radio", name="ignoreNotice")
          tdiv(class="notice-message", style={backgroundColor: colour}):
            text notice.msg
      tdiv(class="container"):
        v
  result = doctype & $node

proc renderFlat*(v: VNode, cfg: Config): string =
  let ret = buildHtml(html(lang="en")):
    renderHead(cfg)
    body:
      v
  result = doctype & $ret

proc renderFlat*(v: VNode, cfg: Config, notice: Notice): string =
  let ret = buildHtml(html(lang="en")):
    renderHead(cfg)
    body:
      if notice.msg.len > 0:
        let colour =
          case notice.status
          of success:
            colourGreen

          of warn:
            colourYellow

          of failure:
            colourRed

          else:
            colourGray

        tdiv(class="notice-bar"):
          input(id="ignoreNotice", `type`="radio", name="ignoreNotice")
          tdiv(class="notice-message", style={backgroundColor: colour}):
            text notice.msg
      v
  result = doctype & $ret