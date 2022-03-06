import std / options
import karax / [karaxdsl, vdom]
import ../ ../ lib / [ sys ]

proc renderConnectedDevs*(devs: Devices): VNode =
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
          for v in devs.getDevs:
            tr():
              td(): text if v.getMacaddr.get.len != 0: v.getMacaddr.get else: "None"
              td(): text if v.getIpaddr.get.len != 0: v.getIpaddr.get else: "None"
              td(): text if v.getSignal.get.len != 0: v.getSignal.get else: "None"