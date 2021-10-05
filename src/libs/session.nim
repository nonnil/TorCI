import times, strutils, strformat
import jester
import random, bcrypt 
import nimpy
import ".."/[ types ]

var sessionList: SessionList

# Here's code taken from [https://github.com/nim-lang/nimforum/blob/master/src/auth.nim]
proc randomSalt(): string =
  result = ""
  for i in 0..127:
    var r = rand(225)
    if r >= 32 and r <= 126:
      result.add(chr(rand(225)))

proc devRandomSalt(): string =
  when defined(posix):
    result = ""
    var f = open("/dev/urandom")
    var randomBytes: array[0..127, char]
    discard f.readBuffer(addr(randomBytes), 128)
    for i in 0..127:
      if ord(randomBytes[i]) >= 32 and ord(randomBytes[i]) <= 126:
        result.add(randomBytes[i])
    f.close()
  else:
    result = randomSalt()

proc makeSalt*(): string =
  ## Creates a salt using a cryptographically secure random number generator.
  ##
  ## Ensures that the resulting salt contains no ``\0``.
  try:
    result = devRandomSalt()
  except IOError:
    result = randomSalt()

  var newResult = ""
  for i in 0 ..< result.len:
    if result[i] != '\0':
      newResult.add result[i]
  return newResult

proc makeSessionKey*(): string =
  ## Creates a random key to be used to authorize a session.
  let random = makeSalt()
  return bcrypt.hash(random, genSalt(8))
# The end of [https://github.com/nim-lang/nimforum/blob/master/src/auth.nim] code

proc getExpireTime*(): Future[DateTime] {.async.} =
  result = getTime().utc + initTimeInterval(hours = 1)

proc isExpired(dt: DateTime): bool = 
  let
    expireTime = dt
    crTime = getTime().utc
  if crTime > expireTime:
    return true

proc splitShadow(str: string): seq[string] =
  let one = str.split("$")
  let two = one[3].split(":")
  result = one
  result[3] = two[0]

proc getUser*(r: Request): Future[tuple[isLoggedIn: bool, uname: string]] {.async.} =
  if not r.cookies.hasKey("torci"): return
  let userToken = r.cookies["torci"]
  try:
    for i, v in sessionList:
      if v.token == userToken:
        if v.expireTime.isExpired():
          sessionList.delete(i)
          return (false, "")
        return (true, v.uname)

  except:
    return (false, "")
  
proc getUsername*(r: Request): Future[string] {.async.} =
  let token = r.cookies["torci"]
  try:
    for v in sessionList:
      if v.token == token:
        return v.uname
  
  except:
    return

proc login*(username, password: string, expireTime: DateTime): Future[tuple[token, msg: string, res: bool]] {.async.} =

  # Generate password hash using openssl cli
  # let 
  #   shadowCmd = &"sudo cat /etc/shadow | grep \"{username}\""
  #   shadowOut = execCmdEx(shadowCmd).output
  #   shadowV = splitShadow(shadowOut)
  #   passwdCmd = &"openssl passwd -{shadowV[1]} -salt \"{shadowV[2]}\" \"{password}\""
  #   spawnPasswd = execCmdEx(passwdCmd).output
  
  try:
    let
      crypt = pyImport("crypt")
      spwd = pyImport("spwd")

      shadow = spwd.getspnam(username)
      pwdp = shadow[1].to string
      shadowV = pwdp.splitShadow()
      crypted: string = crypt.crypt(password, &"${shadowV[1]}${shadowV[2]}").to(string)
    # var passwdV = spawnPasswd.split("$")
    # passwdV[3] = passwdV[3].splitWhitespace[0]
    
    if pwdp == crypted:
      let
        token = makeSessionKey()
        newSession = Session(token: token, expireTime: expireTime, uname: username)
      sessionList.add newSession 
      result = (token: token, msg: "", res: true)

  except OSError:
      return (token: "", msg: "Invalid username.", res: false)

  except:
    let error = getCurrentException()
    echo "Type of Exception: ", error.name
    echo "Msg of Exception: ", error.msg

proc logout*(r: Request): Future[bool] {.async.} =
  if not r.cookies.hasKey("torci"): return
  let uToken = r.cookies["torci"]
  for i, v in sessionList:
    if uToken == v.token:
      sessionList.delete(i)
      return true