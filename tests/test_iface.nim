import std / [ unittest, options ]
import ".." / src / lib / sys / iface

suite "iface":
  test "parse Iface":
    let
      n = parseIfaceKind("nil")
      wlan0 = parseIfaceKind("wlan0")
    check:
      n.isNone
      wlan0.isSome