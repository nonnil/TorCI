import std / [
  unittest, importutils, terminal,
  options,
  nativesockets, asyncdispatch
]
import results, resultsutils
import karax / vdom as kvdom
import ../ src / lib / sys / service
import ../ src / lib / tor / tor {.all.}
import ../ src / lib / tor / bridges {.all.}
import ../ src / lib / tor / vdom

suite "Tor":
  proc skip() =
    if not waitFor isActiveService("tor"):
      skip()

  test "TorInfo object":
    skip()
    var torInfo: TorInfo

    match waitFor getTorInfo("127.0.0.1", 9050.Port):
      Ok(ret): torInfo = ret
      Err(msg): fail

    check:
      torInfo.isTor

  # test "Test some methods of Tor":
  #   privateAccess(TorInfo)
  #   privateAccess(TorStatus)


  #   var torStatus: TorStatus

  #   match waitFor checkTor("127.0.0.1", 9050.Port):
  #     Ok(status): torStatus = status
  #     Err(msg): styledEcho(fgRed, "[Error] ", fgWhite, msg); skip()

  #   check:
  #     torStatus.isTor
  #     withSome torStatus.exitIp:
  #       some exitIp:
  #         styledEcho(fgGreen, "[Tor is working]")
  #         styledEcho(fgGreen, "[Exit node ip address] ", fgWhite, exitIp)
  #         true
  #       none: false
  
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

    let dom = dummy.render()
    # styledEcho(fgGreen, "[VDom] ", fgWhite, $dom)
    check:
      0 < len($dom)