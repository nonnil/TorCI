import std / [
  unittest, os, osproc,
  asyncdispatch, nativesockets,
]
import ../ server / client

suite "route  AP":
  routerTest "ap":
    GET:
      "/ap"
      "/default/ap"
      "/conf"
      "/default/conf"
      "/status"
      "/default/status"