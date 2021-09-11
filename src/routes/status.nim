import jester 
import ../views/[temp, status]
import ".."/[types, connexion]
import ".."/libs/[syslib, torlib, wirelessManager]
#import sugar

export status

proc routingStatus*(cfg: Config) =
  router status:
    before "/is":
      resp "Loading"

    get "/is":
      if await request.isLoggedIn():
        #resp renderNode(renderMainMenues(await torStatus(), await displayAboutBridges()), request, cfg)
        # respMainMenu(await showMainMenu(request, cfg))
        let
          torS = await getTorStatus(cfg)
          iface = await getActiveIface()
          wlan = iface.input
          crNet = await currentNetwork(wlan)
          sysInfo = await getSystemInfo()
        resp renderNode(
          renderStatusPane(torS, iface, crNet, sysInfo),
          request,
          cfg
        )
      else:
        redirect "/login"
    post "/is":
      if await request.isLoggedIn():
        let renewIp = request.formData.getOrDefault("new_circuit").body
        if renewIp == "0":
          discard renewTorExitIp()
        redirect "/is"
      redirect "/login"
