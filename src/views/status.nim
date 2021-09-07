import karax/[karaxdsl, vdom]
# import ".."/libs/[wirelessManager, syslib]
import tables, asyncdispatch
import ../types

const defStr = "None"

proc renderSystemInfo(sys: SystemInfo): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "System"
    tdiv(class="card-body"):
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "Model"
        tdiv(class="card-text"):
          text if sys.model.len != 0: sys.model else: defStr
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "KernelVer"
        tdiv(class="card-text"):
          text if sys.kernelVersion.len != 0: sys.kernelVersion else: defStr
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "Architecture"
        tdiv(class="card-text"):
          text if sys.architecture.len != 0: sys.architecture else: defStr

proc renderTorInfo(isTor: bool): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "Tor"
    tdiv(class="card-body"):
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "Status"
        tdiv(class="card-text"):
          text if isTor: "Online" else: "Offline"

proc renderNetworkInfo(iface: ActiveIfaceList, crNet: tuple[ssid, ipAddr: string]): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "Network"
    tdiv(class="card-body"):
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "Input"
        tdiv(class="card-text"): 
          text if iface.input != none: $iface.input else: defStr
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "Output"
        tdiv(class="card-text"):
          text if iface.output != none: $iface.output else: defStr
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "SSID"
        tdiv(class="card-text"):
          text if crNet.ssid.len != 0: crNet.ssid else: defStr
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "IP Address"
        tdiv(class="card-text"):
          text if crNet.ipAddr.len != 0: crNet.ipAddr else: defStr
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "VPN"
        tdiv(class="card-text"): text if iface.hasVpn: "is Up" else: defStr

proc renderStatusPane*(isTor: bool, iface: ActiveIfaceList, crNet: tuple[ssid, ipAddr: string], sysInfo: SystemInfo): VNode =
  buildHtml(tdiv(class="cards")):
    renderTorInfo(isTor)
    renderNetworkInfo(iface, crNet)
    renderSystemInfo(sysInfo)
    # renderSystemInfo()
# proc renderStatus*(status: string; bridge: bool): VNode =
#   buildhtml(tdiv(class="status-bar")):
#     tdiv(class="status-ready"):
#       text "Status:"
#     if status == "Tor is working":
#       tdiv(class="tor-status-active"):
#         text status
#     else:
#       tdiv(class="tor-status-deactive"):
#         text status
#     tdiv(class="bridge-status"):
#       tdiv(class=""):
#         if bridge:
#           text "Bridge is on"
#         else:
#           text "Bridge is off"

# proc showStatus*(status: string, bridge: bool): VNode =
#   buildHtml(tdiv(class="menues-container")):
#     renderStatus(status, bridge)
    #renderMenuList((@["Bridge document", "test"], @["/docs/bridge"]))