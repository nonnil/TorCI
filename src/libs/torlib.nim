import os, osproc, asyncdispatch, re, json, strutils, strformat
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

proc socks5req(url, address: string, port: Port, prt: Protocol = GET, data: string = ""): string =
  let curl = easy_init()
  let webData: ref string = new string
  discard curl.easy_setopt(OPT_USERAGENT,
    "Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0")
  case prt
  of GET:
    discard curl.easy_setopt(OPT_HTTPGET, 1)
  of POST:
    discard curl.easy_setopt(OPT_HTTPPOST, 10000)
    discard curl.easy_setopt(OPT_POSTFIELDS, data)
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

# proc torsocks*(url, address: string, port: Port, ): Future[string] {.async.} = 
#   result = url.socks5req(address, port)

proc torsocksGet*(url: string, cfg: Config): Future[string] {.async.} =
  let
    address = cfg.torAddress
    port = cfg.torPort.parseInt.Port
  result = url.socks5req(address, port, GET)

proc torsocksPost*(url: string, cfg: Config, data: string): Future[string] {.async.} =
  let
    address = cfg.torAddress
    port = cfg.torPort.parseInt.Port
  result = url.socks5req(address, port, POST, data)

proc checkTor*(cfg: Config): Future[tuple[isTor: bool, ipAddr: string]] {.async.} =
  try:
    const
      destHost = "https://check.torproject.org/api/ip"
    let
      torch = await destHost.torsocksGet(cfg)
    if torch.len != 0:
      let jObj = parseJson(torch)
      if $jObj["IsTor"] == "true":
        result.isTor = true
      result.ipAddr = jObj["IP"].getStr()
  except:
    return

proc checkGeoIp*(cfg: Config, isTor: bool, ipAddr: string = ""): Future[tuple[country, city: string]] {.async.} =
  const
    whoer = "https://api.whoer.net/v2/geoip2-city"
    ipinfo = "https://ipinfo.io/products/ip-geolocation-api"
  let
    destHost = if isTor: ipinfo else: whoer
    jsonKey = if isTor: "country" else: "country_code"
  # echo "dest host: ", destHost
  let rawRes = if isTor: await destHost.torsocksPost(cfg, "input=" & ipAddr) else: await destHost.torsocksGet(cfg)
  echo "raw data: ", rawRes
  if rawRes.len != 0:
    let jObj = parseJson(rawRes)
    echo "result of api.whoer: ", $jObj
    result.country = jObj{jsonKey}.getStr()
    result.city = jObj{"city"}.getStr()

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
  let
    torch = await checkTor(cfg)
    bridges = await getBridgesStatus()
  result.isOnline = torch.isTor
  result.useObfs4 = bridges.obfs4
  result.useMeekAzure = bridges.meekAzure
  result.useSnowflake = bridges.snowflake
  
proc renewTorExitIp*(): Future[bool] {.async.} =
  const cmd = "sudo -u debian-tor tor-prompt --run 'SIGNAL NEWNYM'"
  let newIp = execCmdEx(cmd)
  echo "renewTor IP: ", &"\"{newIp.output}\""
  if newIp.output == "250 OK":
    return true

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
  let check = socks5Req("https://ipinfo.io/products/ip-geolocation-api", "127.0.0.1", 9050.Port, POST, "input=37.228.129.5")
  echo "result: ", check