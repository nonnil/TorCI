import std / [
  terminal,
  httpclient, httpcore ,nativesockets, asyncdispatch,
  strformat, strutils
]
import jester #validateip

type
  Settings* = ref object of RootObj
    ipaddr: string
    port: Port

method getIpaddr*(settings: Settings): string {.base.} =
  return settings.ipaddr

method getPort*(settings: Settings): Port {.base.} =
  settings.port

proc ipaddr*(settings: Settings, ipaddr: string) =
  # if isValidIp4(ipaddr, "local"):
  settings.ipaddr = ipaddr

proc port*(settings: Settings, port: Port) =
  settings.port = port

proc init*(ipaddr: string, port: Port): Settings =
  result = new Settings
  ipaddr result, ipaddr
  port result, port 

proc start*(address: string, port: Port, paths: seq[string]) {.async.} =
  for path in paths:
    for i in 0..20:
      var client = newAsyncHttpClient()
      let address = fmt"http://{address}:{$port}/{path}"
      styledEcho(fgBlue, "Getting ", address)
      let ret = client.get(address)
      yield ret or sleepAsync(4000)
      if not ret.finished:
        styledEcho(fgYellow, "Timed out")

      elif not ret.failed:
        styledEcho(fgGreen, "Server started!")
        # return
        continue

      else: echo ret.error.msg
      client.close()

proc clientStart*(address: string, port: Port, paths: seq[string]) {.async.} =
  for path in paths:
    for i in 0..20:
      var client = newAsyncHttpClient()
      let address = fmt"http://{address}:{$port}/{path}"
      styledEcho(fgBlue, "Getting ", address)
      let res = client.get(address)
      yield res or sleepAsync(4000)
      if not res.finished:
        styledEcho(fgYellow, "Timed out")
        continue

      elif not res.failed:
        let res = await res
        styledEcho(fgGreen, "Server started!")
        if res.code.is2xx:
          styledEcho fgGreen, "[200 OK]"

        elif res.code.is4xx:
          styledEcho fgRed, "[404 Not Found]"
        
        if await(res.body).len > 0:
          styledEcho fgGreen, "[Response body] ", fgWhite, "body data is not empty."

        break

      else: echo res.error.msg
      client.close()

# when isMainModule:
#   let settings = init("192.168.42.1", 1984.Port)
#   # let ip = settings.getIpaddr
#   # echo ip
#   # var settings = init("0.0.0.0", 1984.Port)
#   waitFor start(settings)