import std / [
  options,
  strutils, strformat
]
import results, optionsutils

type
  CryptPrefix* = enum
    yescrypt = "y"
    gostYescrypt = "gy"
    scrypt = "7"

    bcrypt_a = "2a"
    bcrypt_b = "2b"
    bcrypt_x = "2x"
    bcrypt_y = "2y"

    sha512crypt = "6"
    sha256crypt = "5"
    sha1crypt = "sha1"

    sunMd5 = "md5"
    md5crypt = "1"
    bsdicrypt = "_"
    bigcrypt, descrypt = ""
    nt = "3"

  Shadow* = ref object
    prefix: CryptPrefix 
    salt: string

proc parsePrefix*(str: string): Option[CryptPrefix] =
  try:
    let ret = parseEnum[CryptPrefix](str)
    return some(ret)

  except: return none(CryptPrefix)

proc parseShadow*(passwd: string): Result[Shadow, string] =
  var
    passwd = passwd
    shadow = new Shadow
    expectPrefix: string

  if passwd[0] == '$':
    passwd = passwd[1..(passwd.len - 1)]

  # elif passwd[0] == '_':
  let columns = passwd.split('$')
  expectPrefix = columns[0]

  withSome parsePrefix(expectPrefix):
    some prefix:
      case prefix
      of yescrypt, gostYescrypt:
        if columns.len == 4:
          shadow.salt = fmt"{columns[1]}${columns[2]}"
          shadow.prefix = prefix

      of sha512crypt, sha256crypt:
        if columns.len == 3:
          shadow.salt = columns[1]
          shadow.prefix = prefix

      else: return err("not secure cryptgraphics")
    none: return err("Invalid crypt prefix")

  return ok shadow
  
proc fmtSalt*(shadow: Shadow): string =
  result = fmt"${$shadow.prefix}${shadow.salt}"
