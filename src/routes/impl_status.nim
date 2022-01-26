import options, asyncdispatch
import results, jester
import ".." / [ types, notice ]
import ".." / lib / [ tor ]

template respIO*() =
  var tor = new Tor
  await tor.reload()

  let
    iface = await getActiveIface()
    wlan = iface.input
    crNet = await currentNetwork(wlan)

  resp renderNode(
    renderStatusPane(tor, iface, crNet),
    request,
    user.uname,
    "Status"
  )

template respIO*(n: Notifies) =
  var tor = new Tor
  await tor.reload()

  let
    iface = await getActiveIface()
    wlan = iface.input
    crNet = await currentNetwork(wlan)

  resp renderNode(
    renderStatusPane(tor, iface, crNet),
    request,
    user.uname,
    "Status",
    notifies=n
  )

# proc getIO*(r: jester.Request) {.async.} =

proc postIO*(r: jester.Request): Future[Option[Notifies]] {.async.} =
  let req = r.formData.getOrDefault("tor-request").body

  if req.len > 0:
    case req
    of "new-circuit":
      var tor = new Tor
      let res = tor.reload

      discard renewTorExitIp()

      var notifies = new(Notifies)
      if tor.hasNewExitIp:
        notifies.add success, "Exit node has been changed."

      elif res.isErr:
        notifies.add failure, res.error.msg

      else:
        notifies.add failure, "Request new exit node failed. Please try again later."

      return some(notifies)

    of "restart-tor":
      await restartTor()
      return none(Notifies)

  return none(Notifies)