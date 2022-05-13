import std / [
  options,
  strutils, strformat
]
import results, resultsutils 

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

proc parsePrefix*(str: string): Result[CryptPrefix, string] =
  try:
    let ret = parseEnum[CryptPrefix](str)
    return ok(ret)

  except: return err("Failure to parse hashing method of shadow")

proc readAsShadow*(passwd: string): Result[Shadow, string] =
  var
    passwd = passwd
    shadow = new Shadow
    expectPrefix: string

  try:
    if passwd[0] == '$':
      passwd = passwd[1..(passwd.len - 1)]

    # elif passwd[0] == '_':
    let columns = passwd.split('$')
    expectPrefix = columns[0]

    match parsePrefix(expectPrefix):
      Ok(prefix):
        case prefix
        of yescrypt, gostYescrypt:
          if columns.len == 4:
            shadow.salt = fmt"{columns[1]}${columns[2]}"
            shadow.prefix = prefix

        of sha512crypt, sha256crypt:
          if columns.len == 3:
            shadow.salt = columns[1]
            shadow.prefix = prefix

        else: return err("Invalid hashing method")
      Err(msg): return err(msg)

    return ok shadow
  except OSError as e: return err(e.msg)
  except IOError as e: return err(e.msg)
  except ValueError as e: return err(e.msg)
  except KeyError as e: return err(e.msg)
  except: return err("Something went wrong")
  
proc fmtSalt*(shadow: Shadow): string =
  result = fmt"${$shadow.prefix}${shadow.salt}"
