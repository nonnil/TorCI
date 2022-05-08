# import std / options
import results

type
  State* = enum
    success 
    warn
    failure

  Notice = ref object of RootObj
    state: State
    msg: string

  Notifies* = ref object
    notice: seq[Notice]

method getState*(n: Notice): State {.base.} =
  n.state

method getMsg*(n: Notice): string {.base.} =
  n.msg

method len*(n: Notifies): int {.base.} =
  n.notice.len

method isEmpty*(n: Notifies): bool {.base.} =
  n.len == 0

proc new*(): Notifies =
  Notifies()

func add*(n: var Notifies, state: State, msg: string) =
  if msg.len == 0: return
  let notice = Notice(state: state, msg: msg)
  n.notice.add notice

func add*(n: var Notifies, r: Result[void, string]) =
  if r.isErr:
    n.add(failure, r.error)

iterator items*(n: Notifies): tuple[i: int, n: Notice] {.inline.} =
  var i: int
  while i < n.len:
    yield (i, n.notice[i])
    inc i

import std / [ strutils ]
import karax / [ karaxdsl, vdom, vstyles ]
method render*(notifies: Notifies): VNode {.base.} =
  const
    colourGreen = "#2ECC71"
    colourYellow = ""
    # colourGray = "#afafaf"
    colourRed = "#E74C3C"
  result = new VNode
  for i, n in notifies.notice:
    let colour =
      case n.getState
      of success:
        colourGreen

      of warn:
        colourYellow

      of failure:
        colourRed

    result = buildHtml(tdiv(class="notify-bar")):
      input(`for`="notify-msg" & $i, class="ignore-notify", `type`="checkbox", name="ignoreNotify")
      tdiv(id="notify-msg" & $i, class="notify-message", style={backgroundColor: colour}):
        text n.getMsg