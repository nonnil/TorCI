import jester#, results, resultsutils
import karax / [ karaxdsl, vdom ]
import ../ server
import ".." / ".." / ".." / src / lib / hostap
import ".." / ".." / ".." / src / views / renderutils
import ".." / ".." / ".." / src / routes / tabs
import ".." / ".." / ".." / src / notice

template tab(): Tab =
  buildTab:
    "Ap" = "/ap"
    "Def / Ap" = "/default" / "ap"
    "Conf" = "/conf"
    "Def / Conf" = "/default" / "conf"

router ap:
  get "/tab":
    resp $tab().render("")
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

    # resp $hostap.conf
    #   .render(false)
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