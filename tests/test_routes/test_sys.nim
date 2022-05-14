import std / [
  unittest,
  os, osproc,
  asyncdispatch, nativesockets
]
import ../ server / client

suite "route  Sys":
  routerTest "sys":
    GET:
      "/passwd"