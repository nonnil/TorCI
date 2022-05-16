import std / [ options, importutils ] 
import jester
import karax / [ karaxdsl, vdom ]
import ../ tests / server / server
import ".." / src / notice 
import ".." / src / lib / sys
import ".." / src / lib / hostap
import ".." / src / renderutils
import ".." / src / routes / tabs

router network:
  template tab(): Tab =
    buildTab:
      "Bridges" = "/net" / "bridges"
      "Interfaces" = "/net" / "interfaces"
      "Wireless" = "/net" / "wireless"

  get "/net/wireless":
    privateAccess(HostAp)
    privateAccess(HostAp)
    privateAccess(HostApConf)
    privateAccess(HostApStatus)
    privateAccess(Devices)
    privateAccess(Device)
    let hostap = HostAp(
      conf: HostApConf(
        iface: some(wlan0),
        ssid: "Mirai-bot",
        password: "changeme",
        band: 'a',
        channel: "36",
        isHidden: true
      ),
      status: HostApStatus(isActive: true)
    )

    let devs = Devices(
      list: @[
        Device(
        macaddr: "33:cb:49:23:fc",
        ipaddr: "192.168.42.11",
        signal: "-66 dBm"
        ),
        Device(
          macaddr: "43:3b:dc:c9:a6:f8",
          ipaddr: "192.168.42.14",
          signal: "-49 dBm"
        ),
        Device(
          macaddr: "cf:f9:d5:f6:91:f9",
          ipaddr: "192.168.42.13",
          signal: "-41 dBm"
        ),
        Device(
          macaddr: "77:42:4d:c6:90:32",
          ipaddr: "192.168.42.12",
          signal: "-50 dBm"
        )
      ]
    )
    const isModel3 = false

    resp: render "Wireless":
      tab: tab
      container:
        hostap.render(isModel3)
        devs.render()

serve(network, 1984.Port)