import ../src/libs/syslib
import ../src/types

const
  torci: string = "torci"
  torbox: string = "torbox"

# let
#   cs = psExists(wlan0)
#   csS = if cs: "working" else: "not found"
# echo torci, " is ", csS
# let
#   bs = psExists(torbox)
#   bsS = if bs: "working" else: "not found"
# echo torbox, " is ", bsS

var s = dhclientWork(wlan0)
echo if s: "found " else: "not found ", "dhclient ", $wlan0
s = dhclientWork(wlan1)
echo if s: "found " else: "not found ", "dhclient ", $wlan1
s = dhclientWork(eth0)
echo if s: "found " else: "not found ", "dhclient ", $eth0
s = dhclientWork(eth1)
echo if s: "found " else: "not found ", "dhclient ", $eth1

for v in IfaceKind:  
  let r = ifaceExists(v)
  echo $v, " exists: ", $r
  if r:
    let s = isStateup(v)
    echo "  ", $v, " stateup: ", $s
    let ip = hasStaticIp(v)
    echo "  ", $v, " has ip address: ", $ip
    let rt = isRouter(v)
    echo "  ", $v, " is ", if rt: "a Router" else: "not a Router"
