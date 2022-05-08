import std / [
  options,
  unittest, importutils,
  terminal
]
import results, optionsutils
import ../ src / lib / crypt {.all.}
import ../ src / lib / clib / c_crypt

suite "Cryptgraphics":
  test "Test prefix parse":
    privateAccess(CryptPrefix)
    let yescrypt_prefix = "y"

    withSome parsePrefix(yescrypt_prefix):
      some prefix:
        check:
          prefix == yescrypt
      none: styledEcho(fgRed, "[Error] ", fgWhite, "prefix parse id failed.")

  test "Test parse on yescrypt":
    privateAccess(Shadow)
    let passwd = "$y$j9T$C5QGAtTr38W/K2jMJ3uTV/$Z5uBSxY.JoKyWiSfUumJTKjiJQFAlAuMfY9YHvAyBmB:19076:0:99999:7:::"
    let ret = parseShadow(passwd)
    if ret.isErr:
      styledEcho(fgRed, "[Error] ", fgWhite, "parseShadow returned err.")

    let
      prefix = ret.get.prefix
      salt = ret.get.salt

    styledEcho(fgBlue, "[Prefix] ", fgWhite, $prefix)
    styledEcho(fgBlue, "[Salt] ", fgWhite, salt)
    styledEcho(fgGreen, "[Success encryption] ", fgWhite, crypt("trickleaks", fmtSalt(ret.get)))
    # check:
  test "Test parse on sha512crypt":
    privateAccess(Shadow)
    let passwd = "$6$D.3Q1uJwc5TIs.g3$VnU8JwwjxWN15Vo2M1CCcf3dr5FJUN9cPUNls0DKW9pknjEwrESA0uGdxMpB735uYJbYBMz86GbkliwrhJVWo.:19068:0:99999:7:::"
    let ret = parseShadow(passwd)
    if ret.isErr:
      styledEcho(fgRed, "[Error] ", fgWhite, "returned err on parse sha512crypt.")

    let
      prefix = ret.get.prefix
      salt = ret.get.salt

    styledEcho(fgBlue, "[Prefix] ", fgWhite, $prefix)
    styledEcho(fgBlue, "[Salt] ", fgWhite, salt)
    styledEcho(fgGreen, "[Success encryption] ", fgWhite, crypt("trickleaks", fmtSalt(ret.get)))