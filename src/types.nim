import jester
import times

type
  Session* = object
    token*: string
    expireTime*: DateTime
    # createdTime*: DateTime
  
  SessionList* = seq[Session]

  UserSession* = object
    token*: string
    req*: Request
  
  Protocol* = enum
    GET = "get",
    POST = "post"
  
  TorStatus* = object
    isOnline*: bool
    exitNodeIp*: string
    exitNodeGeo*: string
    useObfs4*: bool
    useMeekAzure*: bool
    useSnowflake*: bool
    bridgeMode*: bool
    connectedVpn*: bool

  Status* = enum
    success 
    warn
    failure
    active
    normal
    deactive
    online
    offline

  Notice* = ref object
    state*: Status
    message*: string
  
  HostAp* = object
    ssid*: string
    password*: string
    band*: string
    channel*: string
    ssidCloak*: string
    power*: string

  CardKind* = enum
    nord, editable

  Menu* = ref object
    text*: seq[string]
    anker*: seq[string]
  
  IfaceKind* = enum
    none = "none"
    eth0 = "eth0"
    eth1 = "eth1"
    wlan0 = "wlan0"
    wlan1 = "wlan1"
    ppp0 = "ppp0"
    usb0 = "usb0"
    tun0 = "tun0"
    
  Wifi* = object of RootObj
    bssid*: string
    channel*: string
    dbmSignal*: string
    quality*: string
    security*: string
    essid*: string
    isEss*: bool
    isHidden*: bool

  WifiList* = seq[Wifi]

  SystemInfo* = object
    architecture*: string
    kernelVersion*: string
    model*: string
    uptime*: int
    localtime*: int

  ActiveIfaceList* = tuple
    input, output: IfaceKind
    hasVpn: bool
  # NetInterfaces* = ref object
  #   kind*: NetInterKind
  #   status*: Status
    #eth0*, eth1*, wlan0*, wlan1*, pop0*, usb0*, tun0*: Status

  EditType* = enum
    text, select

  Card* = ref object  
    kind*: CardKind
    path*: string
    status*: seq[Status]
    str*: seq[string]
    message*: seq[string]
    editType*: seq[EditType]

  Cards* = ref object
    subject*: seq[string]
    card*: seq[Card]
  
  Config* = ref object
    address*: string
    port*: int
    useHttps*: bool
    title*: string
    torciVer*: string
    torboxVer*: string
    hostname*: string
    staticDir*: string
    torAddress*: string
    torPort*: string
