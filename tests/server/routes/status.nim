import std / options
import jester
import ../ server
import results, resultsutils
import karax / [ vdom ]
import ".." / ".." / ".." / src / notice 
import ".." / ".." / ".." / src / lib / tor
import ".." / ".." / ".." / src / lib / sys
import ".." / ".." / ".." / src / lib / wirelessManager

router status:

  get "/torinfo/default":
    # empty object
    var
      torInfo = TorInfo.default()
    
    resp $torInfo.render()

  get "/torinfo":
    var
      ti: TorInfo
      notifies: Notifies

    match await getTorInfo("127.0.0.1", 9050.Port):
      Ok(ret): ti = ret
      Err(msg): notifies.add(failure, msg)
    
    resp $ti.render()

  get "/iface":
    # empty object
    var
      ioInfo: IoInfo = IoInfo.new()
      connectedAp = ConnectedAp.new()
      notifies = Notifies.new()
    
    match await getIoInfo():
      Ok(iface):
        ioInfo = iface
        if isSome(ioInfo.internet):
          let wlan = ioInfo.internet.get

          match await getConnectedAp(wlan):
            Ok(ap): connectedAp = ap
            Err(msg): notifies.add failure, msg
      Err(msg): notifies.add failure, msg

    resp $ioInfo.render(connectedAp)
  
  get "/iface/default":
    let
      ioInfo: IoInfo = IoInfo.new()
      ap: ConnectedAp = ConnectedAp.new()

    resp $ioInfo.render(ap)

  get "/systeminfo/default":
    let sysInfo = SystemInfo.default()
    resp $sysInfo.render()

  get "/systeminfo":
    var
      sysInfo = SystemInfo.default()
      notifies = Notifies.new()

    match await getSystemInfo():
      Ok(ret): sysInfo = ret
      Err(msg): notifies.add(failure, msg)

    resp $sysInfo.render()

  post "/io":
    let val = request.formData.getOrDefault("tor-request").body
    echo "hey"
    resp Http200, val

serve(status, 1984.Port)