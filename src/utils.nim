import std / strutils
import types

template test*(nim: untyped) =
  when defined test:
    nim

template test*(nim: untyped) =
  when defined test:
    nim
  else:
    quit(QuitFailure)

proc parseIface*(iface: string): IfaceKind =
  parseEnum[IfaceKind](iface, unkwnIface) 