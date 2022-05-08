import std / [
  unittest, importutils, terminal,
  options,
  nativesockets, asyncdispatch
]
import results, optionsutils
import karax / vdom as kvdom
import ../ src / lib / sys / service
import ../ src / lib / tor / tor {.all.}
import ../ src / lib / tor / bridges {.all.}
import ../ src / lib / tor / vdom

suite "Tor tests":
  test "Test some methods of Tor":
    privateAccess(TorInfo)
    privateAccess(TorStatus)

    if not waitFor isActiveService("tor"):
      skip()

    let 
      ta = newTorAddress("127.0.0.1", 9050.Port)
    let torStatus = waitFor ta.get.checkTor()

    if torStatus.isErr:
      styledEcho(fgRed, "[Error] ", fgWhite, torStatus.error)
      skip()

    check:
      torStatus.get.isTor
      withSome torStatus.get.getExitIp:
        some exitIp:
          styledEcho(fgGreen, "[Tor is working]")
          styledEcho(fgGreen, "[Exit node ip address] ", fgWhite, exitIp)
          true
        none: false
  
  test "Test vdom rendering with TorInfo":
    privateAccess(TorInfo)
    privateAccess(TorStatus)
    privateAccess(Bridge)
    let
      status = TorStatus(
        isTor: true,
        exitIp: "1.1.1.1"
      )
      bridge = Bridge(
        kind: BridgeKind.obfs4,
        useBridges: true
      )

    let dummy = TorInfo(
      status: status,
      bridge: bridge
    )

    let dom = dummy.rendering()
    # styledEcho(fgGreen, "[VDom] ", fgWhite, $dom)
    check:
      len($dom) > 0