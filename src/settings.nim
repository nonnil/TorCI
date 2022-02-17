import config
import lib / [ sys, torbox ]
# import lib / tor / tor

export config

const configPath {.strdefine.} = "./torci.conf"
let (cfg*, _) = getConfig(configpath)
var sysInfo* = getSystemInfo()
let torboxVer = getTorboxVersion()
sysInfo.torboxVer = torboxVer