import std / [
  unittest, os, osproc,
  asyncdispatch, nativesockets,
]
import ../ server / client

suite "route status":
  # const
  #   paths = @[ "torinfo", "iface", "systeminfo" ]

  # # start process
  # let process: Process = start("status")

  # waitFor clientStart("0.0.0.0", 1984.Port, paths)

  # kill(process)
  routerTest "status":
    GET:
      "/torinfo"
      "/iface"
      "/systeminfo"

    # POST:
    #   "/io": {"tor-request": "renew"}
