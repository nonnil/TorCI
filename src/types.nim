import std / [ uri ]
import std / [ nativesockets ]
import lib / hostap
import lib / sys / [ iface ]

type
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