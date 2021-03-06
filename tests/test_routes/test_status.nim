import std / [
  unittest, os, osproc,
  asyncdispatch, nativesockets,
]
import ../ server / client

suite "route status":
  routerTest "status":
    GET:
      "/status"
      "/default/status"
      "/tor"
      "/default/tor"
      "/iface"
      "/default/iface"
      "/sys"
      "/default/sys"

    # POST:
    #   "/io": {"tor-request": "renew"}
