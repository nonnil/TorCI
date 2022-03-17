import std / [ unittest, re, strutils ]

suite "torbox":
  proc getTorboxVersion(hname: string): string =
    if hname.match(re"TorBox(\d){3}"):
      # hname.delete(0, 5)
      let version = hname[6..8]
      result = version.insertSep('.', 1)

  test "Check TorBox version":
    var hostname = "TorBox050"
    let h = getTorboxVersion(hostname)

    check:
      "0.5.0" == h

# proc getTorboxVersion*(): string =
#   var hname = $getHostname()
#   if hname.match(re"TorBox(\d){3}"):
#     hname.delete(0..5)
#     result = hname.insertSep('.', 1)

