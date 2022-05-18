import std / [ options, importutils ] 
import jester
import karax / [ karaxdsl, vdom ]
import ../ tests / server / server
import ".." / src / notice 
import ".." / src / lib / tor {.all.}
import ".." / src / lib / sys
import ".." / src / lib / wirelessManager
import ".." / src / renderutils
import ".." / src / routes / tabs

router stat:
  get "/io":
    privateAccess(TorInfo)
    privateAccess(TorStatus)
    privateAccess(Bridge)
    privateAccess(IoInfo)
    privateAccess(SystemInfo)
    privateAccess(CpuInfo)
    privateAccess(ConnectedAp)
    var
      ti = TorInfo(
        status: TorStatus(isTor: true),
        bridge: Bridge(
          useBridges: true,
          kind: obfs4
        )
      )

      si = SystemInfo(
        cpu: CpuInfo(
          model: "Raspberry Pi 4 Model B Rev 1.2",
          architecture: "ARMv7 Processor rev 3 (v7l)"
        ),
        kernelVersion: "5.10.17-v7l+",
        torboxVer: "0.5.0"
      )

      ii = IoInfo(
        internet: some(wlan0),
        hostap: some(wlan1)
      )

      ap = ConnectedAp(
        ssid: "Mirai-bot",
        ipaddr: "192.168.19.84"
      )

    resp: render "Status":
      container:
        ti.render()
        ii.render(ap)
        si.render()

serve(stat, 1984.Port)