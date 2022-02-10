import std / os

const
  torrc* = "/etc" / "tor" / "torrc"
  torrcBak* = "/etc" / "tor" / "torrc.bak"
  tmpTorrc* = "/tmp" / "torrc.tmp"
  torlog* = "/var" / "log" / "tor" / "notices.log"