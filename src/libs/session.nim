import times, strutils, strformat, sequtils, osproc
import jester
import hmac, nimpy
import ".."/[ types ]

var sessionList: SessionList

proc getExpireTime*(): Future[DateTime] {.async.} =
  result = getTime().utc + initTimeInterval(hours = 1)

# proc init(session: Sessiondb) =
#   session.token = ""
  
#[
proc checkLoggedIn*(session: Session) =
  if not session.req.cookies.hasKey("token"): return
  let userToken = session.req.cookies["token"]
  for v in userSession:
    if v.token == userToken:
      session.token
]#

proc isExpired(dt: DateTime): bool = 
  let
    expireTime = dt
    crTime = getTime().utc
  if crTime > expireTime:
    return true

proc comparePasswd(shadow, passwd: seq[string]): bool =
  for i in 1..3:
    if shadow[i] != passwd[i]:
      return false
  return true

proc splitShadow(str: string): seq[string] =
  let one = str.split("$")
  let two = one[3].split(":")
  result = one
  result[3] = two[0]

template initUserSession*() =
  var crSession {.inject.}: UserSession
  new(crSession)
  init(crSession)
  crSession.req = request
  if request.cookies.len > 0:
    checkLoggedIn(crSession)

proc isLoggedIn*(r: Request): Future[bool] {.async.} =
  if not r.cookies.hasKey("torci"): return
  let userToken = r.cookies["torci"]
  try:
    for i, v in sessionList:
      if v.token == userToken:
        if v.expireTime.isExpired():
          sessionList.delete(i)
          return false
        return true

  except:
    return false

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
        token = hmac_sha256("test", username & password & $epochTime()).toHex
        newSession = Session(token: token, expireTime: expireTime)
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