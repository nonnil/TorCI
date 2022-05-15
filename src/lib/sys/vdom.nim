import std / [ options ]
import karax / [ karaxdsl, vdom ]
import sys
# from ".." / ".." / settings import cfg, sysInfo
import ../ wirelessManager
from ../../ settings import cfg

method render*(self: SystemInfo): VNode {.base.} =
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
                  text if self.model.len != 0: self.model else: defStr
          tr():
            td(): text "Kernel"
            td():
              strong():
                tdiv():
                  text if self.kernelVersion.len != 0: self.kernelVersion else: defStr
          tr():
            td(): text "Architecture"
            td():
              strong():
                tdiv():
                  text if self.architecture.len != 0: self.architecture else: defStr
          tr():
            td(): text "TorBox Version"
            td():
              strong():
                tdiv():
                  text if self.torboxVersion.len > 0: self.torboxVersion else: "Unknown"
          tr():
            td(): text "TorCI Version"
            td():
              strong():
                tdiv():
                  text cfg.torciVer

func render*(self: IoInfo, ap: ConnectedAp): VNode =
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
                  let internet = self.internet
                  text if internet.isSome: $get(internet)
                    else: defStr
          tr():
            td(): text "Host AP"
            td():
              strong():
                tdiv():
                  # let hostap = io.getHostap
                  # text if hostap.isSome: $hostap.get else: defStr
                  let hostap = self.hostap
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
                  text if self.vpnIsActive: "is Up" else: defStr

func render*(self: Devices): VNode =
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
          for v in self.list:
            tr():
              td(): text if v.macaddr.len != 0: v.macaddr else: "None"
              td(): text if v.ipaddr.len != 0: v.ipaddr else: "None"
              td(): text if v.signal.len != 0: v.signal else: "None"

proc renderSys*(): VNode =
  buildHtml(tdiv):
    tdiv(class="buttons"):
      button(): text "Reboot TorBox"
      button(): text "Shutdown TorBox"

proc renderPasswdChange*(): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "User password"
      form(`method`="post", action="/sys/passwd", enctype="multipart/form-data"):
        table(class="full-width box-table"):
          tbody():
            tr():
              td(): text "Current password"
              td():
                strong():
                  input(`type`="password", `required`="", name="crPassword")
            tr():
              td(): text "New password"
              td():
                strong():
                  input(`type`="password", `required`="", name="newPassword")
            tr():
              td(): text "New password (Retype)"
              td():
                strong():
                  input(`type`="password", `required`="", name="re_newPassword")
        button(class="btn-apply", `type`="submit", name="postType", value="chgPasswd"): text "Apply"
        
proc renderChangePassControlPort*(): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Change"

proc renderLogs*(): VNode =
  buildHtml(tdiv(class="")):
    form(`method`="post", action="/sys", enctype="multipart/form-data", class="form"):
      button(`type`="submit", name="postType", value="eraseLogs", class="eraser"): text "Erase Logs"