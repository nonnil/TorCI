import os, asyncdispatch, re, json, strutils
import libcurl
import ".."/[types]
const
  torrc = "/etc" / "tor" / "torrc"
  torrcBak = "/etc" / "tor" / "torrc.bak"
  tmp = "/tmp" / "torrc.tmp"

proc curlWriteFn(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer): int =
  
  let outbuf = cast[ref string](outstream)
  outbuf[] &= buffer
  result = size * count

proc socks5Req(url, address: string, port: Port): string =
  let curl = easy_init()
  let webData: ref string = new string
  discard curl.easy_setopt(OPT_USERAGENT,
    "Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0")
  discard curl.easy_setopt(OPT_HTTPGET, 1)
  discard curl.easy_setopt(OPT_WRITEDATA, webData)
  discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
  discard curl.easy_setopt(OPT_URL, url)
  discard curl.easy_setopt(OPT_PROXYTYPE, 5)
  discard curl.easy_setopt(OPT_PROXY, address)
  discard curl.easy_setopt(OPT_PROXYPORT, port)
  discard curl.easy_setopt(OPT_TIMEOUT, 5)

  let ret = curl.easy_perform()
  if ret == E_OK:
    result = webData[]
  else: return

proc torsocks*(url, address: string, port: Port): Future[string] {.async.} = 
  result = url.socks5Req(address, port)
  
proc torsocks*(url: string, cfg: Config): Future[string] {.async.} = 
  let
    address = cfg.torAddress
    port = cfg.torPort.parseInt.Port
  result = url.socks5Req(address, port)

proc isTorActive*(cfg: Config): Future[bool] {.async.} =
  try:
    const
      destHost = "https://check.torproject.org/api/ip"
    let
      torch = await destHost.torsocks(cfg)
    if torch.len != 0:
      let jObj = parseJson(torch)
      if $jObj["IsTor"] == "true":
        return true
  except:
    return

proc getBridgesStatus*(): Future[tuple[obfs4, meekAzure, snowflake: bool]] {.async.} =
  var
    obfs4: bool
    meekAzure: bool
    snowflake: bool
  try:
    let rc = readFile(torrc)
    for line in rc.splitLines():
      if line.startsWith("Bridge obfs4 "):
        if not obfs4: obfs4 = true
        continue
      elif line.startsWith("Bridge meek_lite "):
        if not meekAzure: meekAzure = true
        continue
      elif line.startsWith("Bridge snowflake "):
        if not snowflake: snowflake = true
        continue
  except: return
  result.obfs4 = obfs4
  result.meekAzure = meekAzure
  result.snowflake = snowflake
  
proc getTorStatus*(cfg: Config): Future[TorStatus] {.async.} =
  result.isOnline = await isTorActive(cfg)
  let bridges = await getBridgesStatus()
  result.useObfs4 = bridges.obfs4
  result.useMeekAzure = bridges.meekAzure
  result.useSnowflake = bridges.snowflake

# This function deactivates the bridge relay.
proc deactivateBridgeRelay*() =
  try:
    let
      torrc = readFile(torrc)
      bridge = torrc.findAll(re"BridgeRelay.\d+")[0]
    when defined(debugCi):
      echo "BridgeRelay in Torrc: ", bridge
    if bridge == "BridgeRelay 1":
      let
        orPort = torrc.findAll(re"^ORPort.*")[0].splitWhitespace()[1]
        obfs4Port = torrc.findAll(re"^ServerTransportListenAddr.*")[0].split(":")[1]
      var nTorrc: string
      nTorrc = torrc.multiReplace(@[
        (re"BridgeRelay", "#BridgeRelay"),
        (re"ORPort", "#ORPort"),
        (re"ExtORPort", "#ExtORPort"),
        (re"ServerTransportPlugin", "#ServerTransportPlugin"), 
        (re"ServerTransportListenAddr", "#ServerTransportListenAddr"),
        (re"ContactInfo", "#ContactInfo"),
        (re"Nickname", "#Nickname")
      ])
      discard execShellCmd("sudo iptables -D INPUT -p tcp --dport $sORPORT -j ACCEPT")
      discard execShellCmd("sudo iptables -D INPUT -p tcp --dport $sOBFS4PORT -j ACCEPT")
  except:
    return
  
when isMainModule:
  let bridges = waitFor getBridgesStatus()
  echo "obfs4: ", bridges.obfs4
  echo "meekAzure: ", bridges.meekAzure
  echo "snowflake: ", bridges.snowflake