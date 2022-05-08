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
          for v in devs:
            tr():
              td(): text if v.macaddr.len != 0: v.macaddr else: "None"
              td(): text if v.ipaddr.len != 0: v.ipaddr else: "None"
              td(): text if v.signal.len != 0: v.signal else: "None"