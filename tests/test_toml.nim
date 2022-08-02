import std / [ unittest, os ]
import toml_serialization
import ../ src / toml

suite "TOML":
  test "parse":
    let t = Toml.loadFile("torci.toml", TorCi, "TorCI")
    check t.version == "0.1.3"

  test "compile time":
    const
      fn = "./" / "torci.toml"
      x = Toml.loadFile(fn, TorCi, "TorCI")

    check x.version == "0.1.3"