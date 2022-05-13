import std / [
  os, osproc,
  nativesockets, asyncdispatch,
  json, strutils,
]
import results, resultsutils
import torsocks, torcfg, bridges
import ../ sys / [ service ]
import ../ ../ settings

export torsocks, bridges

type
  TorInfo* = ref object of RootObj
    # setting*: TorSettings
    status*: TorStatus
    bridge*: Bridge

  # TorSettings* = ref object
  #   bridge: Bridge

  TorStatus* = ref object
    isTor: bool
    isVPN: bool
    exitIp: string

proc default*(_: typedesc[TorInfo]): TorInfo =
  result = TorInfo.new()
  result.status = TorStatus.new()
  result.bridge = Bridge.new()

method isTor*(self: TorStatus): bool {.base.} =
  self.isTor

method isVpn*(self: TorStatus): bool {.base.} =
  self.isVpn

method exitIp*(self: TorStatus): string {.base.} =
  self.exitIp

method isEmpty*(self: TorStatus): bool {.base.} =
  self.exitIp.len == 0

method isTor*(self: TorInfo): bool {.base.} =
  self.status.isTor

method isVpn*(self: TorInfo): bool {.base.} =
  self.status.isVpn

method exitIp*(self: TorInfo): string {.base.} =
  self.status.exitIp

method isEmpty*(self: TorInfo): bool {.base.} =
  self.status.exitIp.len == 0

proc checkTor*(torAddr: string, port: Port): Future[Result[TorStatus, string]] {.async.} =
  const destHost = "https://check.torproject.org/api/ip"
  let checkTor = waitFor destHost.torsocks(torAddr, port)
  if checkTor.len == 0: result.err "connection failed"
  try:
    let jObj = parseJson(checkTor)
    if $jObj["IsTor"] == "true":
      var ts = TorStatus.new
      ts.isTor = true
      ts.exitIp = jObj["IP"].getStr()
      result.ok ts
  except JsonParsingError as e: return err(e.msg)

proc getTorInfo*(toraddr: string, port: Port): Future[Result[TorInfo, string]] {.async.} =
  var
    status: TorStatus
    bridge: Bridge

  match waitFor checkTor(toraddr, port):
    Ok(sta): status = sta
    Err(msg): return err(msg)

  match waitFor getBridge():
    Ok(ret): bridge = ret
    Err(msg): return err(msg)

  var ret = TorInfo.new()
  ret.status = status
  ret.bridge = bridge
  return ok(ret)

proc renewTorExitIp*(): Future[bool] {.async.} =
  const cmd = "sudo -u debian-tor tor-prompt --run 'SIGNAL NEWNYM'"
  let newIp = execCmdEx(cmd)
  if newIp.output == "250 OK":
    return true

proc renewTorExitIp*(ti: var TorInfo): Future[bool] {.async.} =
  const cmd = "sudo -u debian-tor tor-prompt --run 'SIGNAL NEWNYM'"
  let newIp = execCmdEx(cmd)
  if newIp.output == "250 OK":
    match await checkTor(cfg.torAddress, cfg.torPort):
      Ok(stat): ti.status = stat; return true
      Err(_): return false
  
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