import os, osproc, re, asyncdispatch, strutils
import ".." / [types]
import std / [sha1, json]
import torsocks, binascii

proc getBridgeStatuses*(): Future[BridgeStatuses] {.async.} =
  try:
    let rc = readFile(torrc)
    for line in rc.splitLines():

      if line.startsWith("Use Bridges 1"):
        result.useBridges = true
        continue

      elif line.startsWith("Bridge obfs4 "):
        result.obfs4 = true
        continue

      elif line.startsWith("Bridge meek_lite "):
        result.meekAzure = true
        continue

      elif line.startsWith("Bridge snowflake "):
        result.snowflake = true
        continue

  except: return
  
proc isRunning*(fp: string, conf: Config): Future[bool] {.async.} =

  const destHost = "https://onionoo.torproject.org" / "details?lookup="

  let
    hash = secureHash(a2bHex(fp))
    ret = await (destHost & $hash).torsocks(conf)

  if ret.len > 0:
    let
      j = parseJson(ret)
      b = j["bridges"]

    if b.len > 0:
      if b[0]{"running"}.getStr() == "true":
        return true

proc getObfs4Count(): tuple[activated, deactivated, total: int] =
  let rc = readFile(torrc)
  for v in rc.splitLines():
    if v.startsWith("Bridge obfs4 "):
      result.activated += 1
      result.total += 1
    elif v.startsWith("#Bridge obfs4 "):
      result.deactivated += 1
      result.total += 1
      
# This function deactivates the bridge relay.
proc deactivateBridgeRelay() =
  var
    rc = readFile(torrc)
    activeRelay: bool
    orport, obfs4port: string

  for v in rc.splitLines():
    if v.startsWith("BridgeRelay 1"):
      activeRelay = true

  if activeRelay:
    for v in rc.splitLines():
      if v.startsWith("ORPort"):
        orport = v.splitWhitespace()[1]

      elif v.startsWith("ServerTransportListenAddr"):
        obfs4port = v.split(":")[1]
    
    rc = rc.replacef(re"BridgeRelay\s(\d+)", "#BridgeRelay $1")
    rc = rc.replacef(re"ORPort\s(\d+)", "#ORPort $1")
    rc = rc.replacef(re"ExtORPort\s(\w+)", "#ExtORPort $1")
    rc = rc.replacef(re"ServerTransportPlugin\s(.*)", "#ServerTransportPlugin $1")
    rc = rc.replacef(re"ServerTransportListenAddr\s(.*)", "#ServerTransportListenAddr $1")
    rc = rc.replacef(re"ContactInfo\s(.*)", "#ContactInfo $1")
    rc = rc.replacef(re"Nickname\s(.*)", "#Nickname $1")
    rc = rc.replacef(re"BridgeDistribution\s(.*)", "#BridgeDistribution $1")

    torrc.writeFile rc

    if (orport.len != 0) and (obfs4port.len != 0):
      discard execCmd("sudo iptables -D INPUT -p tcp --dport $sORPORT -j ACCEPT")
      discard execCmd("sudo iptables -D INPUT -p tcp --dport $sOBFS4PORT -j ACCEPT")
    
proc activateAllConfiguredObfs4*() {.async.} =
  let (activated, _, _) = getObfs4Count()
  if activated > 0:
    deactivateBridgeRelay()
    var rc = readFile(torrc)
    rc = rc.replacef(re"#UseBridges\s(\d+)", "UseBridges $1")
    rc = rc.replacef(re"#UpdateBridgesFromAuthority\s(\d+)", "UpdateBridgesFromAuthority $1")
    rc = rc.replacef(re"#ClientTransportPlugin meek_lite,obfs4\s(.*)", "ClientTransportPlugin meek_lite,obfs4 $1")
    rc = rc.replacef(re"ClientTransportPlugin snowflake\s(.*)", "#ClientTransportPlugin snowflake $1")
    rc = rc.replacef(re"Bridge snowflake\s(.*)", "#Bridge snowflake $1")
    rc = rc.replacef(re"Bridge meek_lite\s(.*)", "#Bridge meek_lite $1")

    torrc.writeFile(rc)
    
proc isObfs4(obfs4: string): bool =
  let splitted = obfs4.splitWhitespace()
  if splitted.len == 5:

    if (splitted[0] == "obfs4") and
    (splitted[1].match(re"(\d+\.){3}(\d+):\d+")) and
    (splitted[2].match(re".+")) and
    (splitted[3].match(re"cert=.+")) and
    (splitted[4].match(re"iat-mode=\d")):
      return true

    else:
      return false
    
proc isSnowflake(snowflake: string): bool =
  let s = snowflake.splitWhitespace()
  if s.len == 2:
    
    if (s[0].match(re"(\d+\.){3}(\d+):\d+")) and
    (s[1].match(re".+")):
      return true
    
    else:
      return false

proc addObfs4*(bridge: string): Future[tuple[res: bool, msg: string]] {.async.} =
  if bridge.isObfs4():
    var rc = readFile(torrc)
    rc &= "\n" & bridge
    torrc.writeFile(rc)
    return (true, "")

proc addObfs4*(bridges: seq[string]): Future[seq[tuple[res: bool, msg: string]]] {.async.} =
  for bridge in bridges:
    let ret = waitFor addObfs4(bridge)
    if not ret.res:
      result.add ret
      
proc activateSnowflake*(): Future[bool] {.async.} =
  let rc = readFile(torrc)
  for line in rc.splitLines():
    if line.startsWith("#Bridge snowflake "):
      let strs = line.splitWhitespace(2)
      if isSnowflake(strs[2]):
        return true
      
    
# proc activateOnlineObfs4*() {.async.} =