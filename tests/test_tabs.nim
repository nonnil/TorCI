import std / [
  unittest
]
import ../ src / routes / tabs

suite "Tabs":
  test "Test some method is work correctly.":
    let tab = Tab.new
    check:
      tab.isEmpty

  test "build macro":
    let tab = buildTab:
      # "Bridges" = "/net" / "bridges"
      "Bridges" = "/net" / "bridges"
      "Tor" = "/tor" / "bridges"

      "Passwd" = "/sys" / "passwd"
      "Logs" = "/sys" / "logs"

    check:
      tab[3].label == "Logs"
      tab.len == 4