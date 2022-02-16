import options, asyncdispatch, nativesockets
import results
import jester
import tabs
import ".." / [ types, notice, settings ]
import ../ lib / tor / tor

template respIO*() =
  var tor: Tor = init(cfg.torAddress, cfg.torPort)
  let ret = tor.reload()

  let
    iface = await getActiveIface()
    wlan = iface.input
    crNet = await currentNetwork(wlan)

  resp renderNode(
    renderStatusPane(tor, iface, crNet),
    request,
    request.getUserName,
    "Status"
  )

template respIO*(n: Notifies) =
  var tor: Tor = init(cfg.torAddress, cfg.torPort)
  let ret = tor.reload()

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

proc postIO*(r: jester.Request): Future[Option[Notifies]] {.async.} =
  let req = r.formData.getOrDefault("tor-request").body

  if req.len > 0:
    case req
    of "new-circuit":
      var tor: Tor = init(cfg.torAddress, cfg.torPort)
      let res = tor.reload

      discard renewTorExitIp()

      var notifies = new(Notifies)
      if tor.hasNewExitIp:
        notifies.add success, "Exit node has been changed."

      elif res.isErr:
        notifies.add failure, res.error

      else:
        notifies.add failure, "Request new exit node failed. Please try again later."

      return some(notifies)

    of "restart-tor":
      await restartTor()
      return none(Notifies)

  return none(Notifies)