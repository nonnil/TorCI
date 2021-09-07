import parsecfg except Config
import types, strutils
import typeinfo

proc get*[T](config: parseCfg.Config; s, v: string; default: T): T =
  let val = config.getSectionValue(s, v)
  if val.len == 0: return default

  when T is int: parseInt(val)
  elif T is bool: parseBool(val)
  elif T is string: val

proc getConfig*(path: string): (Config, parseCfg.Config) =
  var
    cfg = loadConfig(path)
    address: string = "192.168.42.1"
    torAddress: string = "127.0.0.1"
    torport: string = "9050"
  let conf = Config(
    address: cfg.get("Server", "address", address),
    port: cfg.get("Server", "port", 1984),
    useHttps: cfg.get("Server", "https", true),
    title: cfg.get("Server", "title", "TorBox"),
    torciVer: cfg.get("Server", "torciVer", "nil"),
    torboxVer: cfg.get("Server", "torboxVer", "nil"),
    staticDir: cfg.get("Server", "staticDir", "./public"),
    torAddress: cfg.get("Server", "torAddress", torAddress),
    torPort: cfg.get("Server", "torPort", torPort)
  )
  return (conf, cfg)
