import std / [
  os, osproc, asyncdispatch,
  json, strutils, strformat,
  options
]
import results, validateip
import torsocks, torcfg, bridges
import ../ sys / [ service ]
import ../ ../ settings

export torsocks, bridges

type
  Tor* = ref object of RootObj
    ipaddr: string
    port: Port
    setting*: TorSettings
    status*: TorStatus
  
  TorSettings* = ref object
    bridge: Bridge

  TorStatus* = ref object
    isTor: bool
    isVPN: bool
    exitIp: string
  
  R = Result[void, string]

proc init*(ipaddr: string, port: Port): Tor

method getIpaddr*(tor: Tor): Option[string] {.base.} =
  return some(tor.ipaddr)

method getPort*(tor: Tor): Option[Port] {.base.} =
  return some(tor.port)

method bridge*(tor: Tor): Bridge {.base.} =
  tor.setting.bridge

proc exitIp*(status: var TorStatus, exitIp: string): R =
  if exitIp.isValidIp4("local"):
    status.exitIp = exitIp
    result.ok
  result.err "Invalid IP address"

proc exitIp*(tor: var Tor, exitIp: string): R =
  ?exitIp(tor, exitIp)

method getExitIp*(status: TorStatus): Option[string] {.base.} =
  if status.exitIp.len > 0:
    return some status.exitIp

method getExitIp*(tor: Tor): Option[string] {.base.} =
  return tor.status.getExitIp

# method isTor*(tor: var Tor): R {.base.} =
#   const destHost = "https://check.torproject.org/api/ip"
#   let checkTor = waitFor destHost.torsocks(tor.getIpaddr.get, tor.getPort.get)
#   if checkTor.len == 1: result.err "connection failed"
#   let jObj = parseJson(checkTor)
#   if $jObj["IsTor"] == "true":
#     tor.status.isOnline = true
#     tor.status.exitIp = jObj["IP"].getStr()
#     result.ok

method isTor*(status: TorStatus): bool {.base.} =
  status.isTor

method isTor*(tor: Tor): bool {.base.} =
  isTor(tor.status)

proc checkTor*(tor: Tor): Future[Result[TorStatus, string]] {.async.} =
  const destHost = "https://check.torproject.org/api/ip"
  let checkTor = waitFor destHost.torsocks(tor.getIpaddr.get, tor.getPort.get)
  if checkTor.len == 0: result.err "connection failed"
  let jObj = parseJson(checkTor)
  if $jObj["IsTor"] == "true":
    var ts = TorStatus.new
    ts.isTor = true
    let _ = exitIp(ts, jObj["IP"].getStr())
    result.ok ts

proc isTor*(tor: var Tor): R =
  let ret = waitFor checkTor(tor)
  if ret.isOk:
    tor.status = ret.get
# method isOnline*(tor: Tor): bool {.base.} =
#   tor.status.isOnline

method compareExitIp*(first, second: TorStatus): bool {.base.} =
  let
    firstIp = first.getExitIp
    secondIp = second.getExitIp
  
  if isSome(firstIp) and isSome(secondIp):
    if firstIp.get == secondIp.get:
      return true

method hasNewExitIp*(tor: var Tor): bool {.base.} =
  var `new` = init(cfg.torAddress, cfg.torPort)
  let ret = waitFor `new`.checkTor

  if ret.isErr: return false

  let
    status = ret.get
    exitIp = status.getExitIp
  if tor.status.exitIp != exitIp.get:
    let ret = exitIp(tor, exitIp.get)
    if ret.isOk:
      return true

method reload*(setting: var TorSettings): Result[void, string] {.base.} =
  ?setting.bridge.reload

method reload*(tor: var Tor): Result[void, string] {.base.} =
  ?tor.setting.reload
  ?tor.isTor

# proc reload*(tor: var Tor): Future[Result[void, string]] {.async.} =
#   ?tor.setting.reload
#   ?tor.isTor

proc ipaddr*(tor: var Tor, ipaddr: string) =
  if not isValidIp4(ipaddr, "local"):
    raise newException(ValueError, "")
  tor.ipaddr = ipaddr

proc port*(tor: var Tor, port: Port) =
  tor.port = port

proc init*(ipaddr: string, port: Port): Tor =
  new result
  ipaddr(result, ipaddr)
  port(result, port)

proc renewTorExitIp*(): Future[bool] {.async.} =
  const cmd = "sudo -u debian-tor tor-prompt --run 'SIGNAL NEWNYM'"
  let newIp = execCmdEx(cmd)
  if newIp.output == "250 OK":
    return true
  
proc restartTor*() {.async.} =
  restartService "tor"
  
proc getTorLog*(): Future[string] {.async.} =
  if not fileExists(torlog):
    return
  let f = readFile(torlog)
  result = f
  
proc spawnTorrc*() =
  const
    torrcOrig = "/home" / "torbox" / "torbox" / "etc" / "tor" / "torrc"
  if not fileExists(torrcOrig):
    return
  copyFile torrcOrig, torrc
  
# when isMainModule:
#   let bridgesS = waitFor getBridgeStatuses()
#   echo "obfs4: ", bridgesS.obfs4
#   echo "meekAzure: ", bridgesS.meekAzure
#   echo "snowflake: ", bridgesS.snowflake
#   let check = socks5("https://ipinfo.io/products/ip-geolocation-api", "127.0.0.1", 9050.Port, POST, "input=37.228.129.5")
#   echo "result: ", check