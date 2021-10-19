import jester, asyncdispatch
import ../views/[temp, status]
import ".."/[types]
import ".."/libs/[session, syslib, torLib, wirelessManager]
#import sugar

export status

proc routingStatus*(cfg: Config, sysInfo: SystemInfo) =
  router status:
    before "/io":
      resp "Loading"

    get "/io":
      let user = await getUser(request)
      if user.isLoggedIn:
        # resp renderNode(renderMainMenues(await torStatus(), await displayAboutBridges()), request, cfg)
        # respMainMenu(await showMainMenu(request, cfg))
        let
          torS = await getTorStatus(cfg)
          iface = await getActiveIface()
          wlan = iface.input
          crNet = await currentNetwork(wlan)
          # sysInfo = await getSystemInfo()
        resp renderNode(
          renderStatusPane(cfg, torS, iface, crNet, sysInfo),
          request,
          cfg,
          user.uname,
          "Status"
        )
      else:
        redirect "/login"

    post "/io":
      let user = await getUser(request)
      if user.isLoggedIn:
        let renewIp = request.formData.getOrDefault("new_circuit").body
        if renewIp == "0":
          discard renewTorExitIp()
        redirect "/io"
      redirect "/login"
