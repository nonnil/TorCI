import config
import lib / [ tor, sys, torbox ]

const configPath {.strdefine.} = "./torci.conf"
let (cfg*, _) = getConfig(configpath)
var sysInfo* = getSystemInfo()
let torboxVer = getTorboxVersion()
sysInfo.torboxVer = torboxVer