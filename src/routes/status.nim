import jester, asyncdispatch
import ../ views / [temp, status]
import ".." / [types]
import ".." / lib / [session, sys, tor, wirelessManager]
#import sugar

export status

template respIo*() =
  resp renderNode(
    renderStatusPane(cfg, torS, iface, crNet, sysInfo),
    request,
    cfg,
    user.uname,
    "Status"
  )

template respIo*(n: Notifies) =
  resp renderNode(
    renderStatusPane(cfg, torS, iface, crNet, sysInfo),
    request,
    cfg,
    user.uname,
    "Status",
    notifies=n
  )

proc routingStatus*(cfg: Config, sysInfo: SystemInfo) =
  router status:

    before "/io":
      resp "Loading"

    get "/io":
      let user = await getUser(request)
      if user.isLoggedIn:
        let
          torS = await getTorStatus(cfg)
          iface = await getActiveIface()
          wlan = iface.input
          crNet = await currentNetwork(wlan)
        respIo()
      else:
        redirect "/login"

    post "/io":
      let user = await getUser(request)
      if user.isLoggedIn:
        let newIpReq = request.formData.getOrDefault("new_circuit").body
        if newIpReq == "1":
          let
            prevS = await getTorStatus(cfg)
            prevIp = prevS.exitIp

          discard renewTorExitIp()

          let
            torS = await getTorStatus(cfg)
            iface = await getActiveIface()
            wlan = iface.input
            crNet = await currentNetwork(wlan)

          let newIp = torS.exitIp
        
          if prevIp != newIp:
            respIo(Notifies(@[Notify(status: success, msg: "Exit node has been changed.")]))
          else:
            respIo(Notifies(@[Notify(status: failure, msg: "Request new exit node failed. Please try again later.")]))
        redirect "/io"
      redirect "/login"
