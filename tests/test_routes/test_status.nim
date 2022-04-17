import std / [
  unittest, os, osproc,
  asyncdispatch, nativesockets,
]
import ../ server / client
import ../ server / utils

suite "route status":
  const
    paths = @[ "torinfo", "iface", "systeminfo" ]

  # start process
  let process: Process = start("status")

  waitFor clientStart("0.0.0.0", 1984.Port, paths)

  kill(process)
