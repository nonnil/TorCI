import karax / [ karaxdsl, vdom ]
import ".." / lib / sys
import ../ lib / tor
import ../ lib / wirelessManager

proc buildStatusPane*(torInfo: TorInfo, sysInfo: SystemInfo , io: IO, ap: ConnectedAp): VNode =
  buildHtml(tdiv(class="cards")):
    torInfo.render()
    io.render(ap)
    sysInfo.render()