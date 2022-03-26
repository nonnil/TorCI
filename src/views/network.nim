import karax / [karaxdsl, vdom, vstyles]
import strformat
import ../ types
import network / [ bridges, ap ]
import ../ lib / [ hostap, sys ]
import ../ lib / sys / [ iface ]

export bridges, ap

proc renderInterfaces*(): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "Interfaces"
    tdiv(class="table table-striped"):
      tdiv(class="table-row thead"):
        tdiv(class="table-header name"): text "Name"
        tdiv(class="table-header status"): text "Status"
    tdiv(class="tbody"):
      tdiv(class="table-row", style={display: "table-row"}):
        tdiv(class="table-item"): text "eth0"
        tdiv(class="buttons"):
          a(href="/net/interfaces/connect/eth0"):
            button(): text "Connect"
      tdiv(class="table-row", style={display: "table-row"}):
        tdiv(class="table-item"): text "eth1"
        tdiv(class="buttons"):
          a(href="/net/interfaces/connect/eth1"):
            button(): text "Connect"
      tdiv(class="table-row", style={display: "table-row"}):
        tdiv(class="table-item"): text "wlan0"
        tdiv(class="buttons"):
          a(href="/net/interfaces/join/?iface=wlan0"):
            button(): text "Open Access"
          a(href="/net/interfaces/join/?iface=wlan0&captive=1"):
            button(): text "Captive Access"
      tdiv(class="table-row", style={display: "table-row"}):
        tdiv(class="table-item"): text "wlan1"
        tdiv(class="buttons"):
          a(href="/net/interfaces/set/?iface=wlan1"):
            button(): text "Open Access"
          a(href="/net/interfaces/join/?iface=wlan1&captive=1"):
            button(): text "Captive Access"
      tdiv(class="table-row", style={display: "table-row"}):
        tdiv(class="table-item"): text "ppp0 or usb0"
        tdiv(class="buttons"):
          a(href="/net/interfaces/connect/usb0"):
            button(): text "Connect"
      tdiv(class="table-row", style={display: "table-row"}):
        tdiv(class="table-item"): text "tun0"
        tdiv(class="buttons"):
          a(href="/net/interfaces/join/tun0"):
            button(): text "Scan"

proc renderWifiConfig*(wlan: IfaceKind, withCaptive: bool; wifiInfo: WifiList; currentNetwork: tuple[ssid, ipAddr: string]): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "Nearby APs"
    tdiv(class="ap-list"):
      tdiv(class="table table-striped"):
        tdiv(class="table-row thead"):
          tdiv(class="table-header signal"): text "Signal"
          tdiv(class="table-header essid"): text "ESSID"
          tdiv(class="table-header channel"): text "Channel"
          tdiv(class="table-header bssid"): text "BSSID"
          tdiv(class="table-header security"): text "Security"
      tdiv(class="tbody"):
        for i, v in wifiInfo:
            # tdiv(class="ap-table"):
          tdiv(class="table-row", style={display: "table-row"}):
            tdiv(class="table-item signal"): text v.quality
            tdiv(class="table-item essid"): text v.essid
            tdiv(class="table-item channel"): text v.channel
            tdiv(class="table-item bssid"): text v.bssid
            tdiv(class="table-item security"): text v.security
            # button(`type`="submit", name="ap", value=v.essid): text "Join"
            tdiv(class="button"):
              label(): text "Join"
              input(class="popup-button", `type`="radio", name="select-network", value="open")
              input(class="popout-button", `type`="radio", name="select-network", value="close")
              tdiv(class="shadow")
              tdiv(class="editable-box"):
                form(`method`="post", action="/net/interfaces/join/" & $wlan, enctype="multipart/form-data"):
                  # tdiv(class="card-table", style=style {visibility: "hidden"}):
                    # label(class="card-title"): text "Interface"
                    # select(name="wlan"):
                      # option(value=wlan): text wlan
                     
                  tdiv(class="card-table bssid"):
                    input(`type`="hidden", name="bssid", value=v.bssid)

                  tdiv(class="card-table essid"):
                    label(class="card-title"): text "SSID"
                    if v.isHidden:
                      input(`type`="text", name="essid", placeholder="ESSID of a Hidden Access Point")
                      input(`type`="hidden", name="cloak", value="1")
                    else:
                      tdiv(): text v.essid
                      input(`type`="hidden", name="essid", value=v.essid)
                      input(`type`="hidden", name="cloak", value="0")

                  tdiv(class="card-table"):
                    label(class="card-title"): text "Password"
                    if v.isEss:
                      tdiv(): text "ESS does not require a password"
                      input(`type`="hidden", name="password", value="")
                      input(`type`="hidden", name="ess", value="1")
                    else:
                      input(`type`="password", name="password")
                      input(`type`="hidden", name="ess", value="0")

                  tdiv(class="card-table", style={display: "none"}):
                    label(class="card-title"): text "Connect to with a Captive portal or not"
                    if withCaptive:
                      input(`type`="checkbox", name="captive", value="1", checked="")
                    else:
                      input(`type`="checkbox", name="captive", value="0")

                  button(`type`="submit", class="btn-join"): text "Join Network"
    if currentNetwork.ssid != "":
      tdiv(class="current-network"):
        span(): text "Connected:"
        tdiv(class="cr-net-ssid"): text currentNetwork.ssid
        tdiv(class="cr-net-ipaddr"): text &"[{currentNetwork.ipAddr}]"
    # tdiv(class="button"):
    #   label(): text "Select Network"
    #   input(class="popup-button", `type`="radio", name="select-network", value="open")
    #   input(class="popout-button", `type`="radio", name="select-network", value="close")
    #   tdiv(class="shadow")
    #   tdiv(class="editable-box"):
    #     form(`method`="post", action="/net/interfaces/join/" & wlan, enctype="multipart/form-data"):
    #       # tdiv(class="card-table", style=style {visibility: "hidden"}):
    #         # label(class="card-title"): text "Interface"
    #         # select(name="wlan"):
    #           # option(value=wlan): text wlan
    #       tdiv(class="card-table essid"):
    #         label(class="card-title"): text "SSID"
    #         select(name="essid"):
    #           for v in wifiInfo:
    #             option(value=v.essid): text v.essid
    #       tdiv(class="card-table"):
    #         label(class="card-title"): text "Password"
    #         input(`type`="password", name="wifi-password")
    #       button(`type`="submit", class="btn-join"): text "Join Network"

proc renderHostApPane*(hostap: HostAp, rpiModel: string, devs: Devices): VNode =
  buildHtml(tdiv(class="cards")):
    render hostap.getConf, rpiModel
    render hostap.getStatus
    renderConnectedDevs(devs)
    
proc renderBridgesPage*(bridgesSta: BridgeStatuses): VNode =
  buildHtml(tdiv(class="cards")):
    renderInputObfs4()
    renderBridgeActions(bridgesSta)