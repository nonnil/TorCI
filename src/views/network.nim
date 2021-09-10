import karax/[karaxdsl, vdom, vstyles]
import jester
import strformat, tables
import ".."/[types]
import temp 
import ../libs/wifiScanner

proc renderTorLogs*(logs: string): VNode =
  buildHtml(tdiv(class="logs-container")):
    if logs == "":
      tdiv(class="logs-text"): text "Tor logs, no exist."
    else:
      pre(class="logs-text"): text logs

proc renderControlePanel*(label:array[0..1, string]; card:array[0..1, Card]): VNode =
  buildHtml(tdiv(class="controle-panel")):
    for i, v in card:
      renderCard(label[i], v)

proc collectComponent*(r:Request; cfg:Config; label:array[0..1, string]; card:array[0..1, Card]; tab:Menu):string =
  result = renderNode(renderControlePanel(label, card), r, cfg, menu=tab)

proc renderTorConfig*(): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "Tor Configuration"
    tdiv(class="card-body"):
      tdiv(class="card-table"):
        tdiv(class="card-title"): text ""

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
          a(href="/net/interfaces/join/wlan0"):
            button(): text "Scan"
      tdiv(class="table-row", style={display: "table-row"}):
        tdiv(class="table-item"): text "wlan1"
        tdiv(class="buttons"):
          a(href="/net/interfaces/join/wlan1"):
            button(): text "Scan"
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

proc renderWifiConfig*(wlan: string, wifiInfo: WifiList; currentNetwork: tuple[ssid, ipAddr: string]): VNode =
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
        # form(`method`="post", action="/net/wifi", enctype="multipart/form-data"):
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
                form(`method`="post", action="/net/interfaces/join/" & wlan, enctype="multipart/form-data"):
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
                      input(`type`="hidden", name="cloak", value="0")
                    else:
                      tdiv(): text v.essid
                      input(`type`="hidden", name="essid", value=v.essid)
                      input(`type`="hidden", name="cloak", value="1")
                  tdiv(class="card-table"):
                    label(class="card-title"): text "Password"
                    if v.isEss:
                      tdiv(): text "ESS does not require a password"
                      input(`type`="hidden", name="password", value="")
                      input(`type`="hidden", name="ess", value="0")
                    else:
                      input(`type`="password", name="password")
                      input(`type`="hidden", name="ess", value="1")
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

proc renderWirelessPowerButton*(): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "HostAP Control"
      table():
        form(`method`="post", action="/net/wireless", enctype="multipart/form-data"):
          button(`type`="submit", class="btn btn-reload", name="status", value="reload"): text "Restart"
          button(`type`="submit", class="btn btn-enable", name="status", value="enable"): text "Enable"
          button(`type`="submit", class="btn btn-disable", name="status", value="disable"): text "Disable"

proc renderWirelessConfig*(hostap: HostAp): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "HostAP Configuration"
        tdiv(class="btn edit-button"):
          svg(`aria-hidden`="true", height="16", viewBox="0 0 16 16", version="1.1", width="16", data-view-component="true", class="octicon octicon-pencil"):
            path(fill-rule="evenodd", d="M11.013 1.427a1.75 1.75 0 012.474 0l1.086 1.086a1.75 1.75 0 010 2.474l-8.61 8.61c-.21.21-.47.364-.756.445l-3.251.93a.75.75 0 01-.927-.928l.929-3.25a1.75 1.75 0 01.445-.758l8.61-8.61zm1.414 1.06a.25.25 0 00-.354 0L10.811 3.75l1.439 1.44 1.263-1.263a.25.25 0 000-.354l-1.086-1.086zM11.189 6.25L9.75 4.81l-6.286 6.287a.25.25 0 00-.064.108l-.558 1.953 1.953-.558a.249.249 0 00.108-.064l6.286-6.286z")
          input(class="opening-button", `type`="radio", name="popout-button", value="open")
          input(class="closing-button", `type`="radio", name="popout-button", value="close")
          tdiv(class="shadow")
          tdiv(class="editable-box"):
            form(`method`="post", action="/net/wireless", enctype="multipart/form-data"):
              tdiv(class="card-table"):
                label(class="card-title"): text "SSID"
                input(`type`="text", name="ssid", placeholder=hostap.ssid)
              tdiv(class="card-table"):
                label(class="card-title"): text "Band"
                select(name="band"):
                  option(value="g"): text "2.5GHz"
                  option(value="a"): text "5GHz"
              tdiv(class="card-table"):
                label(class="card-title"): text "SSID Cloak"
                select(name="ssidCloak"):
                  option(value="hide"): text "Hide"
                  option(value="unhide"): text "Unhide"
              button(`type`="submit", class="btn btn-apply saveBtn", name="saveBtn"): text "Save change"
      table(class="full-width box-table"):
        tbody():
          tr():
            td(): text "SSID"
            td():
              strong():
                tdiv():
                  text hostap.ssid
          tr():
            td(): text "Band"
            td():
              strong():
                tdiv():
                  text case hostap.band
                    of "g":
                      "2.5GHz"
                    of "a":
                      "5GHz"
                    else:
                      "Unknown"
          tr():
            td(): text "SSID Cloak"
            td():
              strong():
                tdiv():
                  text case hostap.ssidCloak
                    of $0:
                      "Visible"
                    of $1:
                      "Hidden"
                    else:
                      "Unknown"
 
proc renderWirelessPane*(hostap: HostAp): VNode =
  buildHtml(tdiv(class="cards")):
    renderWirelessConfig(hostap)
    renderWirelessPowerButton()