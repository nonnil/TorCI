import karax / [ karaxdsl, vdom ]
import jester
import renderutils
import ".." / [ notice, settings ]
import ".." / routes / [ tabs ]
# import re, os

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

proc renderNode*(v: VNode; req: Request; username: string; title: string = "", tab: Tab = Tab.new()): string =
  let node = buildHtml(html(lang="en")):
    renderHead(cfg, title)

    body:
      if tab.isEmpty: renderNav(req, username)
      else: renderNav(req, username, tab)
      tdiv(class="container"):
        v
  result = doctype & $node

proc renderNode*(
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

template render*(v: VNode, title: string): VNode =
  renderNode(v, request, request.getUserName, title)

macro render*(title: string, body: untyped): VNode =