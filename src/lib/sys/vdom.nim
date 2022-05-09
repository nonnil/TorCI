import std / [ options ]
import karax / [ karaxdsl, vdom ]
import sys
# from ".." / ".." / settings import cfg, sysInfo
import ../ wirelessManager
from ../../ settings import cfg

method render*(sysInfo: SystemInfo): VNode {.base.} =
  const defStr = "None"
  buildHtml(tdiv(class="columns full-width")):
    tdiv(class="card card-padding card-sys"):
      tdiv(class="card-header"):
        text "System"
      table(class="table full-width"):
        tbody():
          tr():
            td(): text "Model"
            td():
              strong():
                tdiv():
                  text if sysInfo.model.len != 0: sysInfo.model else: defStr
          tr():
            td(): text "Kernel"
            td():
              strong():
                tdiv():
                  text if sysINfo.kernelVersion.len != 0: sysInfo.kernelVersion else: defStr
          tr():
            td(): text "Architecture"
            td():
              strong():
                tdiv():
                  text if sysInfo.architecture.len != 0: sysInfo.architecture else: defStr
          tr():
            td(): text "TorBox Version"
            td():
              strong():
                tdiv():
                  text if sysInfo.torboxVer.len > 0: sysInfo.torboxVer else: "Unknown"
          tr():
            td(): text "TorCI Version"
            td():
              strong():
                tdiv():
                  text cfg.torciVer

func render*(io: IoInfo, ap: ConnectedAp): VNode =
  const defStr = "None"
  buildHtml(tdiv(class="columns")):
    tdiv(class="card card-padding card-sky"):
      tdiv(class="card-header"):
        text "Network"
      table(class="table full-width"):
        tbody():
          tr():
            td(): text "Internet"
            td():
              strong():
                tdiv():
                  let internet = io.internet
                  text if internet.isSome: $get(internet)
                    else: defStr
          tr():
            td(): text "Host AP"
            td():
              strong():
                tdiv():
                  # let hostap = io.getHostap
                  # text if hostap.isSome: $hostap.get else: defStr
                  let hostap = io.hostap
                  text if hostap.isSome: $get(hostap)
                    else: defStr

          tr():
            td(): text "SSID"
            td():
              strong():
                tdiv():
                  text if ap.ssid.len != 0: ap.ssid else: defStr
          tr():
            td(): text "IP Address"
            td():
              strong():
                tdiv():
                  text if ap.ipAddr.len != 0: ap.ipaddr else: defStr
          tr():
            td(): text "VPN"
            td():
              strong():
                tdiv():
                  text if io.vpnIsActive: "is Up" else: defStr
