import karax/[karaxdsl, vdom, vstyles]
import jester
import renderutils
import ".."/types
import strutils
import typetraits
# import re, os

const
  doctype = "<!DOCTYPE html>\n"
  colourGreen = "#2ECC71"
  colourYellow = ""
  colourGray = "#afafaf"
  colourRed = "#E74C3C"
  
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
              form(`method`="post", action="/net/torctl", enctype="multipart/form-data"):
                button(`type`="submit", name="restartTor", value="1"):
                  icon "cw"
                  tdiv(class="btn-text"): text "Restart Tor"
              form(`method`="post", action="/logout", enctype="multipart/form-data"):
                button(`type`="submit", name="signout", value="1"):
                  icon "logout"
                  tdiv(class="btn-text"): text "Log out"
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

proc renderNode*(v: VNode; req: Request; cfg: Config; username: string; title: string = "", menu = Menu()): string =
  let node = buildHtml(html(lang="en")):
    renderHead(cfg, title)
    body:
      if menu.text.len != 0:
        renderNav(cfg, req, username, menu)
      else:
        renderNav(cfg, req, username)
      tdiv(class="container"):
        v
  result = doctype & $node

proc renderNode*(
  v: VNode;
  req: Request;
  cfg: Config;
  username: string;
  title: string = "",
  menu = Menu();
  notify: Notify): string =

  let node = buildHtml(html(lang="en")):
    renderHead(cfg, title)
    body:
      if menu.text.len != 0:
        renderNav(cfg, req, username, menu)
      else:
        renderNav(cfg, req, username)
      let colour =
        case notify.status
        of success:
          colourGreen

        of warn:
          colourYellow

        of failure:
          colourRed

        else:
          colourGray

      tdiv(class="notify-bar"):
        input(class="ignore-notify", `type`="checkbox", name="ignoreNotify")
        tdiv(class="notify-message", style={backgroundColor: colour}):
          text notify.msg
      tdiv(class="container"):
        v
  result = doctype & $node

proc renderNode*(
  v: VNode;
  req: Request;
  cfg: Config;
  username: string;
  title: string = "",
  menu = Menu();
  notifies: Notifies): string =

  let node = buildHtml(html(lang="en")):
    renderHead(cfg, title)
    body:
      if menu.text.len != 0:
        renderNav(cfg, req, username, menu)
      else:
        renderNav(cfg, req, username)
      for i, n in notifies:
        let colour =
          case n.status
          of success:
            colourGreen

          of warn:
            colourYellow

          of failure:
            colourRed

          else:
            colourGray

        tdiv(class="notify-bar"):
          input(`for`="notify-msg" & $i, class="ignore-notify", `type`="checkbox", name="ignoreNotify")
          tdiv(id="notify-msg" & $i, class="notify-message", style={backgroundColor: colour}):
            text n.msg
      tdiv(class="container"):
        v
  result = doctype & $node

proc renderFlat*(v: VNode, cfg: Config, title: string = ""): string =
  let ret = buildHtml(html(lang="en")):
    renderHead(cfg, title)
    body:
      v
  result = doctype & $ret

proc renderFlat*(v: VNode, cfg: Config, notify: Notify, title: string = ""): string =
  let ret = buildHtml(html(lang="en")):
    renderHead(cfg, title)
    body:
      if notify.msg.len > 0:
        let colour =
          case notify.status
          of success:
            colourGreen

          of warn:
            colourYellow

          of failure:
            colourRed

          else:
            colourGray

        tdiv(class="notify-bar"):
          input(id="ignoreNotify", `type`="radio", name="ignoreNotify")
          tdiv(class="notify-message", style={backgroundColor: colour}):
            text notify.msg
      v
  result = doctype & $ret