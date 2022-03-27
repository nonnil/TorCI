import std / [ os ]
import tabs 
import ".." / [ notice, types ]
import ".." / lib / [ session, hostap ]

func netTab*(): Tab =
  buildTab:
    "Bridges" = "/net" / "bridges"
    "Interfaces" = "/net" / "interfaces"
    "Wireless" = "/net" / "wireless"


template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string]) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, request.getUserName, "Network management", netTab())

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string], n: Notifies) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, request.getUserName, netTab(), n)

template respBridges*() =
  let bridgesSta = await getBridgeStatuses()
  resp renderNode(renderBridgesPage(bridgesSta), request, request.getUserName, "Bridges", netTab())

template respBridges*(n: Notifies) =
  let bridgesSta = await getBridgeStatuses()
  resp renderNode(renderBridgesPage(bridgesSta), request, request.getUserName, "Bridges", netTab(), n)

template respMaintenance*() =
  resp renderNode(renderClosed(), request, request.getUserName, "Under maintenance", netTab())