import std / options
import jester, results, resultsutils
import karax / [ karaxdsl, vdom ]
import ../ server
import ".." / ".." / ".." / src / lib / [ hostap, sys ]
import ".." / ".." / ".." / src / renderutils
import ".." / ".." / ".." / src / routes / tabs
import ".." / ".." / ".." / src / notice

template tab(): Tab =
  buildTab:
    "Ap" = "/ap"
    "Def / Ap" = "/default" / "ap"
    "Conf" = "/conf"
    "Def / Conf" = "/default" / "conf"

router ap:
  get "/hostap":
    var 
      hostap: HostAp = HostAp.default()
      # iface = conf.iface
      devs = Devices.new()
      nc = Notifies.default() 
    
    hostap = await getHostAp()
    let
      isModel3 = await rpiIsModel3()
      iface = hostap.conf.iface
    
    if iface.isSome:
      match await getDevices(iface.get):
        Ok(ret): devs = ret
        Err(msg): nc.add(failure, msg)

    resp: render "Wireless":
      tab: tab
      notice: nc
      container:
        hostap.render(isModel3)
        devs.render()
  
  get "/default/hostap":
    var 
      hostap: HostAp = HostAp.default()
      # iface = conf.iface
      devs = Devices.new()
      nc = Notifies.default() 

    resp: render "Wireless":
      tab: tab
      notice: nc
      container:
        # hostap.conf.render(false)
        # hostap.status.render()
        hostap.render(false)
        devs.render()

  get "/conf":
    let cf = await getHostApConf()
    resp $cf.render(false)
  
  get "/default/conf":
    let cf = HostApConf.new()
    resp $cf.render(false)
  
  get "/status":
    var sta = await getHostApStatus()
    resp $sta.render()

  get "/default/status":
    let sta = HostApStatus.new()
    resp $sta.render()

  get "/ap":
    var hostap = HostAp.default()
    hostap = await getHostAp()

    resp: render "Access Point":
      tab: tab
      container:
        hostap.conf.render(false)
        hostap.status.render()
  
  get "/default/ap":
    let hostap = HostAp.default()
    resp $hostap.conf
      .render(false)

serve(ap, 1984.Port)