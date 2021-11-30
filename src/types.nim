import std / [times, uri]
import std / nativesockets

type
  Session* = ref object
    token*: string
    expireTime*: DateTime
    uname*: string
    # createdTime*: DateTime
  
  SessionList* = seq[Session]

  Spwd* {.importc: "struct spwd", header: "<shadow.h>".} = ptr object
    name* {.importc: "sp_namp".}: cstring
    passwd* {.importc: "sp_pwdp".}: cstring
    sp_lstchg {.importc: "sp_lstchg".}: clong
    min {.importc: "sp_min".}: clong
    max {.importc: "sp_max".}: clong
    warn {.importc: "sp_warn".}: clong
    inact {.importc: "sp_inact".}: clong
    expire {.importc: "sp_expire".}: clong
    flag {.importc: "sp_flag".}: culong

  Protocol* = enum
    GET = "get",
    POST = "post"

  ActivateObfs4Kind* {.pure.} = enum
    all, online, select

  BridgeKind* = enum
    obfs4 = "obfs4",
    meekazure = "meek_lite",
    snowflake = "snowflake"

  Obfs4* = object
    ipaddr*: string
    port*: Port
    fingerprint*, cert*, iatMode*: string

  Meekazure* = object
    ipaddr*: string
    port*: Port
    fingerprint*: string
    meekazureUrl*: Uri
    front*: Uri

  Snowflake* = object
    ipaddr*: string
    port*: Port
    fingerprint*: string

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
    torboxVer*: string

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