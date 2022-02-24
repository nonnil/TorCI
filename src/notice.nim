# import std / options
from types import State
import results

type
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

proc add*(n: var Notifies, state: State, msg: string) =
  if msg.len == 0: return
  let notice = Notice(state: state, msg: msg)
  n.notice.add notice

iterator items*(n: Notifies): tuple[i: int, n: Notice] {.inline.} =
  var i: int
  while i < n.len:
    yield (i, n.notice[i])
    inc i