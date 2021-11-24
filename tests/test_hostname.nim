import unittest
import ../ src / utils
import ../ src / lib / torbox

runTest:
  suite "torbox":
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

