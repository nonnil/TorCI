import std / [ nativesockets, sugar, strutils ]
import toml_serialization

export toml_serialization

type
  TorCi* = object
    version*: string
    staticDir*: string
    address*: string
    port*: Port
    # port*: int
    # port*: string

# proc readValue(r: var TomlReader, v: var TorCi) =
#   r.parseTable(k):

proc readValue*(r: var TomlReader, p: var Port) =
  p = r.parseInt(int)
    .Port


proc load*(_: typedesc[TorCi], filename: string = "torci.toml"): TorCi =
  # func load[T](con, key: string, default: T): T =
  #   # let n = (n: string) => when T is int: parseInt(n).Port
  #   #   elif T is string: n
  #   let t = Toml.decode(con, string, key)
  #   when T is Port: parseInt(t).Port
  #   elif T is int: parseInt(t)
  #   elif T is string: t
  # result = new TorCi
  # result.version = Toml
  #   .loadFile(filename, TorCi, "TorCI.version")
  const n = (n: string) => Toml.decode(n, TorCi, "TorCI")
  slurp(filename)
    .n()
  # TorCi(
  #   version: t.load("TorCI.version", "0.0.0"),
  #   staticDir: t.load("TorCI.staticDir", "./public"),
  #   address: t.load("TorCI.address", "0.0.0.0"),
  #   port: t.load("TorCI.port", 1984)
  # )
  #   .Toml.decode(TorCi, "TorCI")
  # Toml.loadFile(filename, TorCi, "TorCI")

  # result.port = Toml
  #   .loadFile(filename, int, "TorCI.port")
  #   .Port