import karax/[karaxdsl, vdom]
import tables, asyncdispatch
import ../types

const defStr = "None"

proc renderSystemInfo(sys: SystemInfo): VNode =
  buildHtml(tdiv(class="columns full-width")):
    tdiv(class="card card-padding card-blue"):
      tdiv(class="card-header"):
        text "System"
      table(class="table full-width"):
        tbody():
          tr():
            td(): text "Model"
            td():
              strong():
                tdiv():
                  text if sys.model.len != 0: sys.model else: defStr
          tr():
            td(): text "KernelVer"
            td():
              strong():
                tdiv():
                  text if sys.kernelVersion.len != 0: sys.kernelVersion else: defStr
          tr():
            td(): text "Architecture"
            td():
              strong():
                tdiv():
                  text if sys.architecture.len != 0: sys.architecture else: defStr

proc renderTorInfo(isTor: bool): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="card card-padding card-tor"):
      tdiv(class="card-header"):
        text "Tor"
      table(class="table full-width"):
        tbody():
          tr():
            td(): text "Status"
            td():
              strong():
                tdiv():
                  text if isTor: "Online" else: "Offline"


proc renderNetworkInfo(iface: ActiveIfaceList, crNet: tuple[ssid, ipAddr: string]): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="card card-padding card-sky"):
      tdiv(class="card-header"):
        text "Network"
      table(class="table full-width"):
        tbody():
          tr():
            td(): text "Input"
            td():
              strong():
                tdiv():
                  text if iface.input != none: $iface.input else: defStr
          tr():
            td(): text "Output"
            td():
              strong():
                tdiv():
                  text if iface.output != none: $iface.output else: defStr
          tr():
            td(): text "SSID"
            td():
              strong():
                tdiv():
                  text if crNet.ssid.len != 0: crNet.ssid else: defStr
          tr():
            td(): text "IP Address"
            td():
              strong():
                tdiv():
                  text if crNet.ipAddr.len != 0: crNet.ipAddr else: defStr
          tr():
            td(): text "VPN"
            td():
              strong():
                tdiv():
                  text if iface.hasVpn: "is Up" else: defStr

proc renderStatusPane*(isTor: bool, iface: ActiveIfaceList, crNet: tuple[ssid, ipAddr: string], sysInfo: SystemInfo): VNode =
  buildHtml(tdiv(class="cards")):
    renderTorInfo(isTor)
    renderNetworkInfo(iface, crNet)
    renderSystemInfo(sysInfo)