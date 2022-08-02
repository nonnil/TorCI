import std / [ unittest ]
import toml_serialization
import ../ src / toml

suite "TOML":
  test "parse":
    let t = Toml.loadFile("torci.toml", TorCi, "TorCI")
    check t.version == "0.1.3"