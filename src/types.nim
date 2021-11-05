import jester
import times, os

type
  Session* = object
    token*: string
    expireTime*: DateTime
    uname*: string
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
    exitIp*: string
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
    
  Notify* = ref object
    status*: Status
    msg*: string
    
  Notifies* = seq[Notify]
  
  HostApConf* = object
    isActive*: bool
    iface*: IfaceKind
    ssid*: string
    password*: string
    band*: string
    channel*: string
    isHidden*: bool 
    power*: string
  
  Query* = object
    iface*: IfaceKind
    withCaptive*: bool
  
  CardKind* = enum
    nord, editable

  Menu* = ref object
    text*: seq[string]
    anker*: seq[string]
  
  IfaceKind* = enum
    unkwnIface = "unkwnIface"
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

  Network* = ref object of Wifi
    # wifiList: WifiList
    wlan*: IfaceKind
    networkId*: int
    password*: string
    hasNetworkId*: bool
    connected*: bool
    scanned*: bool
    logFile*: string
    configFile*: string
    
  BridgeStatuses* = object
    useBridges*: bool
    obfs4*: bool
    meekAzure*: bool
    snowflake*: bool
    
  ConnectedDevs* = seq[tuple[macaddr, ipaddr, signal: string]]

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

const
  model3* = "Raspberry Pi 3 Model B Rev"
  torrc* = "/etc" / "tor" / "torrc"
  torrcBak* = "/etc" / "tor" / "torrc.bak"
  tmp* = "/tmp" / "torrc.tmp"
  runfile* = "/home" / "torbox" / "torbox" / "run" / "torbox.run"
  hostapd* = "/etc" / "hostapd" / "hostapd.conf"
  hostapdBak* = "/etc" / "hostapd" / "hostapd.conf.tbx"
  crda* = "/etc" / "default" / "crda"
  torlog* = "/var" / "log" / "tor" / "notices.log"