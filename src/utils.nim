import std / strutils
import types

template forTest*(nim: untyped) =
  when defined test:
    nim

template runTest*(nim: untyped) =
  when defined test:
    nim
  else:
    quit(QuitFailure)

proc parseIface*(iface: string): IfaceKind =
  parseEnum[IfaceKind](iface, unkwnIface) 