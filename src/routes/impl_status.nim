import options, asyncdispatch, nativesockets
import results
import jester
import ".." / [ notice, settings ]
import ".." / lib / sys
import ../ lib / tor / tor
import ../ lib / [ session, wirelessManager ]
import ../ views / [ temp, status ]

template respIO*() =
  let
    tor: Tor = init(cfg.torAddress, cfg.torPort)
    torStatus = waitFor tor.checkTor()

  let
    iface = await getIO()
    wlan = iface.getInternet.get
    crNet = await currentNetwork(wlan)

  resp renderNode(
    renderStatusPane(tor, iface, crNet),
    request,
    request.getUserName,
    "Status"
  )

template respIO*(n: Notifies) =
  let
    tor: Tor = init(cfg.torAddress, cfg.torPort)
    torStatus = waitFor tor.checkTor()

  let
    iface = await getActiveIface()
    wlan = iface.input
    crNet = await currentNetwork(wlan)

  resp renderNode(
    renderStatusPane(tor, iface, crNet),
    request,
    request.getUserName,
    "Status",
    notifies=n
  )

# proc postIO*(r: jester.Request): Future[Option[Notifies]] {.async.} =
#   let req = r.formData.getOrDefault("tor-request").body

#   if req.len > 0:
#     case req
#     of "new-circuit":
#       var tor: Tor = init(cfg.torAddress, cfg.torPort)
#       let res = await tor.reload

#       await renewTorExitIp()

#       var notifies = new(Notifies)
#       if tor.hasNewExitIp:
#         notifies.add success, "Exit node has been changed."

#       elif res.isErr:
#         notifies.add failure, res.error

#       else:
#         notifies.add failure, "Request new exit node failed. Please try again later."

#       return some(notifies)

#     of "restart-tor":
#       await restartTor()
#       return none(Notifies)

#   return none(Notifies)

proc doTorRequest*(r: jester.Request): Future[Option[string]] {.async.} =
  let req = r.formData.getOrDefault("tor-request").body

  if req.len > 0:
    case req
    of "new-circuit":
      var tor: Tor = init(cfg.torAddress, cfg.torPort)
      var notifies = new(Notifies)
      let ret = await tor.checkTor

      if ret.isOk:
        tor.status = ret.get
      
      else:
        notifies.add failure, ret.error

      discard await renewTorExitIp()

      if tor.hasNewExitIp:
        notifies.add success, "Exit node has been changed."

      # elif ret.isErr:
        # notifies.add failure, ret.error

      else:
        notifies.add failure, "Request new exit node failed. Please try again later."

      let ifaces = await getIO()
      let iface = ifaces.getInternet
      if iface.isSome:
        let
          wlan = iface.get
          crNet = await currentNetwork(wlan)

        let ret = renderNode(
          renderStatusPane(tor, ifaces, crNet),
          r,
          r.getUserName,
          "Status",
          notifies=notifies
        )
        return some(ret)

    of "restart-tor":
      await restartTor()
      return none(string)
      # redirect "/io"
