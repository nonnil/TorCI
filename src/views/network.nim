import karax/[karaxdsl, vdom, vstyles]
import jester
import tables, strformat
import ".."/[types]
import temp, renderutils
# import ../libs/wifiScanner

proc renderChannelSelect(hd: SystemInfo, band: string): VNode =
  buildHtml(select(name="channel")):
    option(selected="selected"): text "-- Select a channel --"
    if hd.model == model3:
      option(value="ga"): text "1 at 20 MHz"
      option(value="gc"): text "2 at 20 MHz"
      option(value="ge"): text "3 at 20 MHz"
      option(value="gg"): text "4 at 20 MHz"
      option(value="gi"): text "5 at 20 MHz"
      option(value="gk"): text "6 at 20 MHz (default)"
      option(value="gm"): text "7 at 20 MHz"
      option(value="go"): text "8 at 20 MHz"
      option(value="gq"): text "9 at 20 MHz"
      option(value="gs"): text "10 at 20 MHz"
      option(value="gu"): text "11 at 20 MHz"

    elif band == "g":
      option(value="ga"): text "1 at 20 MHz"
      option(value="gb"): text "1 at 40 MHz"
      option(value="gc"): text "2 at 20 MHz"
      option(value="gd"): text "2 at 40 MHz"
      option(value="ge"): text "3 at 20 MHz"
      option(value="gf"): text "3 at 40 MHz"
      option(value="gg"): text "4 at 20 MHz"
      option(value="gh"): text "4 at 40 MHz"
      option(value="gi"): text "5 at 20 MHz"
      option(value="gj"): text "5 at 40 MHz"
      option(value="gk"): text "6 at 20 MHz (default)"
      option(value="gl"): text "6 at 40 MHz"
      option(value="gm"): text "7 at 20 MHz"
      option(value="gn"): text "7 at 40 MHz"
      option(value="go"): text "8 at 20 MHz"
      option(value="gp"): text "8 at 40 MHz"
      option(value="gq"): text "9 at 20 MHz"
      option(value="gr"): text "9 at 40 MHz"
      option(value="gs"): text "10 at 20 MHz"
      option(value="gt"): text "10 at 40 MHz"
      option(value="gu"): text "11 at 20 MHz"
      option(value="gv"): text "11 at 40 MHz"

    elif band == "a":
      option(value="aa"): text "36 at 40 MHz (default)"
      option(value="ab"): text "36 at 80 MHz"
      option(value="ac"): text "40 at 40 MHz"
      option(value="ad"): text "40 at 80 MHz"
      option(value="ae"): text "44 at 40 MHz"
      option(value="af"): text "44 at 80 MHz"
      option(value="ag"): text "48 at 40 MHz"
      option(value="ah"): text "48 at 80 MHz"

proc renderTorLog*(log: string): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Tor Log"
      tdiv(class="card-padding"):
        tdiv(class="log-text"): text if log.len > 0: log else: "No Tor log exists"

proc renderTorConfig*(): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Tor Configuration"
      table(class="box-table"):
        tbody():
          tr():
            td(): text ""
            
proc renderObfs4Ctl*(): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Bridges Control"
      form(`method`="post", action="/net/bridgesctl", enctype="multipart/form-data"):
        table(class="full-width box-table"):
          tbody():
            tr():
              td(): text "All configured Obfs4"
              td():
                strong():
                  button(`type`="submit", name="obfs4", value="all"):
                    text "Activate"
            tr():
              td(): text "Online Obfs4 only"
              td():
                strong():
                  button(`type`="submit", name="obfs4", value="online"):
                    text "Activate"
            tr():
              td(): text "Auto Obfs4 "
              td():
                strong():
                  button(`type`="submit", name="auto-add-obfs4", value="1"):
                    text "Add"

proc renderBridgesCtl*(bridgesSta: BridgesStatus): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Bridges Control"
      form(`method`="post", action="/net/bridgesctl", enctype="multipart/form-data"):
        table(class="full-width box-table"):
          tbody():
            tr():
              td(): text "Obfs4"
              td():
                strong():
                  if bridgesSta.obfs4:
                    button(class="btn-general btn-danger", `type`="submit", name="deactivateObfs4", value="1"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="activateObfs4", value="1"):
                      text "Activate"

            tr():
              td(): text "Meek-Azure"
              td():
                strong():
                  if bridgesSta.meekAzure:
                    button(class="btn-general btn-danger", `type`="submit", name="deactivateMeek-azure", value="1"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="activateMeek-azure", value="1"):
                      text "Activate"

            tr():
              td(): text "Snowflake"
              td():
                strong():
                  if bridgesSta.snowflake:
                    button(class="btn-general btn-danger", `type`="submit", name="deactivateSnowflake", value="1"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="activateSnowflake", value="1"):
                      text "Activate"
                    
# proc renderObfs4Add*(): VNode =
#   buildHtml(tdiv(class="columns")):
#     tdiv(class="box"):
#       tdiv(class="box-header"):
#         text "Add Obfs4 Bridge"
#       form(`method`="post", action="/net/bridges", enctype="miltipart/form-data"):
#         table(class="full-width box-table"):
#           tbody():
#             tr():
#               td(): text
          
proc renderInputObfs4*(): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Add Obfs4 Bridges"
      form(`method`="post", action="/net/bridges", enctype="multipart/form-data"):
        textarea(
          class="textarea bridge-input",
          name="obfs4Text",
          placeholder="e.g.\nobfs4 xxx.xxx.xxx.xxx:xxxx cert=abcd.. iat-mode=0\nobfs4 yyy.yyy.yyy.yyy:yyyy cert=abcd.. iat-mode=0",
          required=""
        )
        button(class="btn-apply", `type`="submit"): text "Add Bridges"

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

proc renderHostApControl(conf: HostApConf): VNode =
  buildHtml(tdiv(class="columns width-38")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "HostAP Control"
      tdiv(class="card-padding"):
        form(`method`="post", action="/net/apctl", enctype="multipart/form-data"):
          if conf.isActive:
            button(`type`="submit", class="btn btn-reload", name="ctl", value="reload"): text "Restart"
            button(`type`="submit", class="btn btn-disable", name="ctl", value="disable"): text "Disable"
          else:
            button(`type`="submit", class="btn btn-enable", name="ctl", value="enable"): text "Enable"

proc renderHostApConf(conf: HostApConf, sysInfo: SystemInfo): VNode =
  buildHtml(tdiv(class="columns width-58")):
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
                input(`type`="text", name="ssid", placeholder=conf.ssid)
              tdiv(class="card-table"):
                label(class="card-title"): text "Band"
                input(`type`="radio", name="band", value="g"): text "2.5GHz"
                input(`type`="radio", name="band", value="a"): text "5GHz"
              tdiv(class="card-table"):
                label(class="card-title"): text "channel"
                renderChannelSelect(sysInfo, conf.band)
                  # select(name="channel"):
                  #   option(value="")
              tdiv(class="card-table"):
                if conf.isHidden:
                  label(class="card-title"): text "Unhide SSID"
                  input(`type`="checkbox", name="ssidCloak", value="0")
                else:
                  label(class="card-title"): text "Hide SSID"
                  input(`type`="checkbox", name="ssidCloak", value="1")
              tdiv(class="card-table"):
                label(class="card-title"): text "Password"
                input(`type`="password", name="password", placeholder="Please enter 8 to 64 characters") 
              button(`type`="submit", class="btn btn-apply saveBtn", name="saveBtn"):
                text "Save change"
      table(class="full-width box-table"):
        tbody():
          tr():
            td(): text "SSID"
            td():
              strong():
                tdiv():
                  text conf.ssid
          tr():
            td(): text "Band"
            td():
              strong():
                tdiv():
                  text case conf.band
                    of "g":
                      "2.5GHz"
                    of "a":
                      "5GHz"
                    else:
                      "Unknown"
          tr():
            td(): text "Channel"
            td():
              strong():
                tdiv():
                  text conf.channel
          tr():
            td(): text "SSID Cloak"
            td():
              strong():
                tdiv():
                  text if conf.isHidden: "Hidden" else: "Visible"
          tr():
            td(): text "Password"
            td():
              strong():
                if conf.password.len != 0:
                  tdiv(class="password_field_container"):
                    tdiv(class="black_circle")
                    icon "eye-off"
                    input(class="btn show_password", `type`="radio", name="password_visibility", value="show")
                    input(class="btn hide_password", `type`="radio", name="password_visibility", value="hide")
                    tdiv(class="shadow")
                    tdiv(class="password_preview_field"):
                      tdiv(class="shown_password"): text conf.password
                else:
                  tdiv():
                    text "No password has been set"
                    
proc renderConnectedDevs*(devs: ConnectedDevs): VNode =
  buildHtml(tdiv(class="columns full-width")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Connected Devices"
      table(class="full-width box-table"):
        tbody():
          tr():
            th(): text "MAC Address"
            th(): text "IP Address"
            th(): text "Signal"
          for v in devs:
            tr():
              td(): text if v.macaddr.len != 0: v.macaddr else: "None"
              td(): text if v.ipAddr.len != 0: v.ipAddr else: "None"
              td(): text if v.signal.len != 0: v.signal else: "None"
 
proc renderHostApPane*(conf: HostApConf, sysInfo: SystemInfo, devs: ConnectedDevs): VNode =
  buildHtml(tdiv(class="cards")):
    renderHostApConf(conf, sysInfo)
    renderHostApControl(conf)
    renderConnectedDevs(devs)
    
proc renderTorPane*(torlog: string): VNode =
  buildHtml(tdiv(class="cards")):
    renderTorConfig()
    renderTorLog(torlog)
    
proc renderBridgesPage*(bridgesSta: BridgesStatus): VNode =
  buildHtml(tdiv(class="cards")):
    renderInputObfs4()
    renderBridgesCtl(bridgesSta)