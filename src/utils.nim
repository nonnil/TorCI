import strutils
import types

proc parseIface*(iface: string): IfaceKind =
  parseEnum[IfaceKind](iface, unkwnIface) 