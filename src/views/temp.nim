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

var currentColour: string

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

proc renderNav(cfg: Config; req: Request; menu = Menu()): VNode =
  result = buildHtml(header(class="headers")):
    nav(class="nav-container"):
      a(class="linker-root", href="/"):
        img(class="logo-file", src="/images/torbox.png")
        tdiv(class="service-name"):text cfg.title
      tdiv(class="caracteres-version"):text "v" & cfg.torboxVer
      tdiv(class="controle"):
        a(class=getNavClass(req.pathInfo, "/io"), href="/io"): text "Status"
        a(class=getNavClass(req.pathInfo, "/net"), href="/net"): text "Network"
        # a(class=getNavClass(req.pathInfo, "/confs"), href="/confs"): text "Configurations"
        # a(class=getNavClass(req.pathInfo, "/docs"), href="/docs"): text "Documents"
        a(class=getNavClass(req.pathInfo, "/sys"), href="/sys"): text "System"
    if menu.text.len != 0:
      renderSubMenu(req, menu)

proc renderCard*(subject: string; element: Card): VNode =
  buildHtml(tdiv(class="card")):
    var 
      body: VNode
      texv: VNode
      tex: string
    tdiv(class="card-header"):
      text subject
      if element.kind == editable:
        tdiv(class="edit-button"):
          label(): text "Edit"
          input(class="opening-button", `type`="radio", name="popout-button", value="open") 
          input(class="closing-button", `type`="radio", name="popout-button", value="close")
          tdiv(class="shadow")
          tdiv(class="editable-box"):
            form(`method`="post", action=element.path, enctype="multipart/form-data",class=""):
              for i, v in element.str:
                tdiv(class="card-table"):
                  label(class="card-title"): text v
                  input(`type`="text", name=v, placeholder=element.message[i])
              button(`type`="submit", class="saveBtn", name="saveBtn"): text "Save change"
              #[
              tdiv(class="inp"):
                label(): text "SSID"
                input(`type`="text", name="ssid")
              tdiv(class="inp"):
                label(): text "Interface"
                input(`type`="text", name="interface")
              ]#

    tdiv(class="card-body"):
      for i, v in element.str:
        tdiv(class="card-table"):
          tdiv(class="card-title"): text v
          currentColour = 
            if element.status[i] == active or element.status[i] == online:
              colourGreen
            elif element.status[i] == deactive or element.status[i] == failure:
              colourRed
            else:
              colourGray

          if element.message[i].len > 0:
            tex = element.message[i]
          else:  tex = "test"
          texv = tree VNodeKind.text
          texv.text = tex
          body = tree(VNodeKind.tdiv, kids=texv)
          body.class = "card-text"
          body.style = style {color: currentColour}
          #add(body, texv)
          #texv.text = $tex
          #add(body, text "tex")
          #body.kids = @[texv]
          body
   
          # old setup for vdom
          #[
          else:
            tdiv(class="card-text", style={color: "#afafaf"}):
              text element.message[i]
          ]#
        #[
        if state[i] == active or state[i] == success:
          tdiv(class="status-text", style={color: "green"}):
            text message[i]
        elif state[i] == deactive:
          tdiv(class="status-text", style={color: "red"}):
            text message[i]
        ]#

proc renderCard*(subject: string; vnode: VNode; `type`: CardKind=nord): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class = "card-header"):
      text subject
      if `type` == editable:
        button(class = "edit-button"):
          text "Edit"
    tdiv(class="card-body"):
      vnode

proc renderCards*(elements: Cards): VNode =
  buildHtml(tdiv(class="cards")):
    var e: Card
    for i, v in elements.subject:
      e = elements.card[i]
      renderCard(v, e)

proc renderPanel*(v: VNode): VNode =
  buildHtml(tdiv(class="main-panel")):
    v

proc renderContainer*(v: VNode): VNode =
  buildHtml(tdiv(class="container-inside")):
    tdiv(class="container-inside")
    renderPanel(v)

var noticeColor: string

proc renderNode*(v: VNode; req: Request; cfg: Config; menu = Menu(); notice = Notice(msg: "")): string =
  let node = buildHtml(html(lang="en")):
    renderHead(cfg)
    body:
      if menu.text.len != 0:
        renderNav(cfg, req, menu)
      else:
        renderNav(cfg, req)
      if notice.msg.len > 0:
        noticeColor =
          if notice.status== success:
            colourGreen
          elif notice.status== warn:
            colourYellow
          elif notice.status== failure:
            colourRed
          else:
            colourGray
        tdiv(class="notice-bar"):
          input(id="ignoreNotice", `type`="radio", name="ignoreNotice")
          tdiv(class="notice-message", style={backgroundColor: noticeColor}):
            text notice.msg
      tdiv(class="container"):
        v
  result = doctype & $node

proc renderFlat*(node: VNode, cfg: Config, notice: Notice = new Notice): string =
  let rNode= buildHtml(html(lang="en")):
    renderHead(cfg)
    body:
      if notice.msg.len > 0:
        noticeColor =
          if notice.status == success:
            colourGreen
          elif notice.status == warn:
            colourYellow
          elif notice.status == failure:
            colourRed
          else:
            colourGray
        tdiv(class="notice-bar"):
          input(id="ignoreNotice", `type`="radio", name="ignoreNotice")
          tdiv(class="notice-message", style={backgroundColor: noticeColor}):
            text notice.msg
      node
  result = doctype & $rNode
