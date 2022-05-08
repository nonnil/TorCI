import std / [
  options,
  asyncdispatch, nativesockets
]
import jester, results
import ".." / [ notice, settings ]
import ".." / lib / sys
import ../ lib / tor / tor
import ../ lib / [ session, wirelessManager ]
import ../ views / [ temp, status ]

template respIO*() =
  let
    torAddress = newTorAddress(cfg.torAddress, cfg.torPort)
    # torStatus = await checkTor(torAddress.get)
    torInfo = await loadTorInfo(torAddress.get)

  # if torStatus.isOk:
  #   tor.status = torStatus.get
  # else:
  #   tor.status = new TorStatus

  let
    iface = await getIO()
    wlan = iface.getInternet.get
    connectedAp = await getConnectedAp(wlan)

  resp renderNode(
    renderStatusPane(torInfo, iface, connectedAp),
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
    connectedAp = await getConnectedAp(wlan)

  resp renderNode(
    renderStatusPane(tor, iface, connectedAp),
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

template doTorRequest*(r: jester.Request) =
  let req = r.formData.getOrDefault("tor-request").body

  if req.len > 0:
    case req
    of "new-circuit":
      let torAddress = newTorAddress(cfg.torAddress, cfg.torPort)
      let ret = await checkTor(torAddress.get)
      var notifies = new(Notifies)

      if ret.isOk:
        discard await renewTorExitIp()

        let newTorStatus = await checkTor(torAddress)
        if not ret.get.compareExitIp(newTorStatus):
          notifies.add success, "Exit node has been changed."

        else:
          notifies.add failure, "Request new exit node failed. Please try again later."
      
      else:
        notifies.add failure, ret.error

      let ifaces = await getIO()
      let iface = ifaces.getInternet
      if iface.isSome:
        let
          wlan = iface.get
          connectedAp = await getConnectedAp(wlan)

        let ret = renderNode(
          renderStatusPane(tor, ifaces, connectedAp),
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
