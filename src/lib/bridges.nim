import std / [os, osproc, re, asyncdispatch, strutils]
import ".." / [types]
import std / [sha1, json, uri]
import torsocks, binascii, sys
from utils import torrc

proc restartTor() =
  restartService "tor"

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

proc splitAddress(address: string): tuple[ipaddr: string, port: Port] =
  let s = address.split(":")
  return (s[0], s[1].parseInt().Port())

proc parseObfs4*(s: string): Obfs4 =
  let el = s.splitWhitespace

  if el.len != 5 or
  not el[1].match(re"(\d+\.){3}(\d+):\d+") or
  not el[3].startsWith("cert=") or
  not el[4].startsWith("iat-mode="): return

  let (ipaddr, port) = splitAddress(el[1])

  result = Obfs4(
    ipaddr: ipaddr,
    port: port,
    fingerprint: el[2],
    cert: el[3].split('=')[1],
    iatMode: el[4].split('=')[1]
  )

proc parseMeekazure*(s: string): Meekazure =
  let el = s.splitWhitespace()
  if el.len != 5 or
  not el[1].match(re"(\d+\.){3}(\d+):\d+") or
  not el[3].startsWith("url=") or
  not el[4].startsWith("front="): return

  let (ipaddr, port) = splitAddress(el[1])

  result = Meekazure(
    ipaddr: ipaddr,
    port: port,
    fingerprint: el[2],
    meekAzureUrl: el[3].split('=')[1].parseUri(),
    front: el[4].split('=')[1].parseUri()
  )
    
proc parseSnowflake*(s: string): Snowflake =
  let el = s.splitWhitespace()
  if el.len != 3 or
  not el[1].match(re"(\d+\.){3}(\d+):\d+"): return

  let (ipaddr, port) = splitAddress(el[1])

  result = Snowflake(
    ipaddr: ipaddr,
    port: port,
    fingerprint: el[2],
  )
  
proc isRunning*(bridge: Obfs4 | Meekazure | Snowflake, conf: Config): Future[bool] {.async.} =

  const destHost = "https://onionoo.torproject.org" / "details?lookup="
  let fp = bridge.fingerprint

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
    
proc activateObfs4*(kind: ActivateObfs4Kind, select: seq[string] = @[""]) {.async.} =
  let (activated, _, _) = getObfs4Count()
  if activated > 0:
    deactivateBridgeRelay()

    var rc = readFile(torrc)
    rc = rc.replacef(re"#UseBridges\s(\d+)", "UseBridges $1")
    rc = rc.replacef(re"#UpdateBridgesFromAuthority\s(\d+)", "UpdateBridgesFromAuthority $1")
    rc = rc.replacef(re"#ClientTransportPlugin meek_lite,obfs4\s(.*)", "ClientTransportPlugin meek_lite,obfs4 $1")
    rc = rc.replacef(re"[^#]ClientTransportPlugin snowflake\s(.*)", "\n#ClientTransportPlugin snowflake $1")
    rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")
    rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")

    case kind
    of ActivateObfs4Kind.all:
      rc = rc.replacef(re"#Bridge obfs4\s(.*)", "Bridge obfs4 $1")
    
    of ActivateObfs4Kind.online:
      rc = rc.replacef(re"#Bridge obfs4\s(.*)", "Bridge obfs4 $1")

    of ActivateObfs4Kind.select:
      rc = rc.replacef(re"#Bridge obfs4\s(.*)", "Bridge obfs4 $1")

    torrc.writeFile(rc)
    restartTor()

proc deactivateObfs4*() {.async.} =
  var rc = readFile torrc
  rc = rc.replacef(re"[^#]UseBridges\s(\d+)", "\n#UseBridges $1")
  rc = rc.replacef(re"[^#]UpdateBridgesFromAuthority\s(\d+)", "\n#UpdateBridgesFromAuthority $1")
  rc = rc.replacef(re"[^#]ClientTransportPlugin meek_lite,obfs4\s(.*)", "\n#ClientTransportPlugin meek_lite,obfs4 $1")
  rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")

  torrc.writeFile rc
  restartTor()
    
proc isObfs4*(bridge: string): bool =
  let s = bridge.splitWhitespace()

  if s.len == 5 and
  s[0] == "obfs4" and
  s[1].match(re"(\d+\.){3}(\d+):\d+") and
  s[2].match(re".+") and
  s[3].match(re"cert=.+") and
  s[4].match(re"iat-mode=\d"):
    return true

  else:
    return false

proc isMeekazure*(bridge: string): bool =
  let s = bridge.splitLines()

  if s.len == 5 and
  s[0] == "meekazure" and
  s[1].match(re"(\d+\.){3}(\d+):\d+") and
  s[2].match(re".+") and
  s[3].match(re"url=.+") and
  s[4].match(re"front=.+"):
    return true

  else:
    return false
    
proc isSnowflake*(bridge: string): bool =
  let s = bridge.splitWhitespace()

  if s.len == 3 and
  s[0] == "snowflake" and
  s[1].match(re"(\d+\.){3}(\d+):\d+") and
  s[2].match(re".+"):
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

proc activateMeekazure*() {.async.} =
  var rc = readFile torrc

  deactivateBridgeRelay()
  await deactivateObfs4()

  rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")
  rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")
  rc = rc.replacef(re"[^#]ClientTransportPlugin snowflake\s(.*)", "\n#ClientTransportPlugin snowflake $1")
  rc = rc.replacef(re"#UseBridges\s(\d+)", "UseBridges $1")
  rc = rc.replacef(re"#UpdateBridgesFromAuthority\s(\d+)", "UpdateBridgesFromAuthority $1")
  rc = rc.replacef(re"#ClientTransportPlugin meek_lite,obfs4\s(.*)", "ClientTransportPlugin meek_lite,obfs4 $1")
  rc = rc.replacef(re"#Bridge meek_lite\s(.*)", "Bridge meek_lite $1")

  torrc.writefile rc

  restartTor()
      
proc deactivateMeekazure*() {.async.} =
  var rc = readFile torrc

  deactivateBridgeRelay()
  await deactivateObfs4()

  rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")
  rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")
  rc = rc.replacef(re"[^#]ClientTransportPlugin snowflake\s(.*)", "\n#ClientTransportPlugin snowflake $1")
  rc = rc.replacef(re"[^#]UseBridges\s(\d+)", "\n#UseBridges $1")
  rc = rc.replacef(re"[^#]UpdateBridgesFromAuthority\s(\d+)", "\n#UpdateBridgesFromAuthority $1")
  rc = rc.replacef(re"[^#]ClientTransportPlugin meek_lite,obfs4\s(.*)", "\n#ClientTransportPlugin meek_lite,obfs4 $1")
  rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")

  torrc.writefile rc

  restartTor()

# proc activateSnowflake*(): Future[bool] {.async.} =
#   var rc: string

#   for line in torrc.lines:
#     if line.startsWith("#Bridge snowflake "):
#       var bridge: string = line
#       bridge.delete(0..<1)
#       return true
    
#     rc.add line

proc activateSnowflake*() {.async.} =
  var rc: string = readFile torrc

  deactivateBridgeRelay()
  await deactivateObfs4()

  rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")
  rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")
  rc = rc.replacef(re"#UseBridges\s(\d+)", "UseBridges $1")
  rc = rc.replacef(re"#UpdateBridgesFromAuthority\s(\d+)", "UpdateBridgesFromAuthority $1")
  rc = rc.replacef(re"#ClientTransportPlugin snowflake\s(.*)", "ClientTransportPlugin snowflake $1")
  rc = rc.replacef(re"#Bridge snowflake\s(.*)", "Bridge snowflake $1")

  torrc.writefile rc

  restartTor()

proc deactivateSnowflake*() {.async.} =
  var rc: string = readFile torrc

  deactivateBridgeRelay()
  await deactivateObfs4()

  rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")
  rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")
  rc = rc.replacef(re"[^#]UseBridges\s(\d+)", "\n#UseBridges $1")
  rc = rc.replacef(re"[^#]UpdateBridgesFromAuthority\s(\d+)", "\n#UpdateBridgesFromAuthority $1")
  rc = rc.replacef(re"[^#]ClientTransport(.*)", "\n#ClientTransport$1")
  rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")

  torrc.writefile rc

  restartTor()
    
# proc activateOnlineObfs4*() {.async.} =