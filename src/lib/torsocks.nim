import libcurl
import asyncdispatch, strutils
import ../types

proc curlWriteFn(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer): int

proc socks5(url, address: string, port: Port, prt: Protocol = GET, data: string = ""): string

proc torsocks*(url: string, cfg: Config, prtc: Protocol = GET): Future[string] {.async.} =
  let
    address = cfg.torAddress
    port = cfg.torPort.parseInt.Port
  result = url.socks5(address, port, prtc)

proc torsocks*(url: string, address: string = "127.0.0.1", port: Port = 9050.Port, prtc: Protocol = GET): Future[string] {.async.} =
  result = url.socks5(address, port, prtc)

proc curlWriteFn(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer): int =
  
  let outbuf = cast[ref string](outstream)
  outbuf[] &= buffer
  result = size * count

proc socks5(url, address: string, port: Port, prt: Protocol = GET, data: string = ""): string =
  let curl = easy_init()
  let webData: ref string = new string
  discard curl.easy_setopt(
    OPT_USERAGENT,
    "Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0"
  )
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