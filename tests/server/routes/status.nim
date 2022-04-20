import jester
import ../ server
import karax / [ vdom ]
import ".." / ".." / ".." / src / lib / tor
import ".." / ".." / ".." / src / lib / sys

router status:

  get "/torinfo":
    # empty object
    let
      torStatus = TorStatus()
      torBridge = Bridge()
      torInfo = TorInfo(status: torStatus, bridge: torBridge)
    
    resp $torInfo.render()

  get "/iface":
    # empty object
    let
      io = IO()
      currentNet: tuple[ssid, ipAddr: string] = ("", "")
    resp $io.render(currentNet)

  get "/systeminfo":
    let sysInfo = SystemInfo()
    resp $sysInfo.render()

  post "/io":
    let val = request.formData.getOrDefault("tor-request").body
    echo "hey"
    resp Http200, val

serve(status, 1984.Port)