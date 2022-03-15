import std / [
  times, options, random,
  strutils, strformat
]
import jester
import bcrypt 
import results
import clib / [ c_crypt, shadow ]

type
  User* = ref object of RootObj
    credential: UserCredential
    uname: string
    # createdTime*: DateTime

  UserCredential = ref object
    token: string
    expireTime: DateTime
  
  UserList = ref object
    users: seq[User]

var userList: UserList = new UserList

# method getUser*(req: jester.Request): User {.base.} =

method getToken*(user: User): string {.base.} =
  if user.credential.token.len > 0:
    return user.credential.token

method getExpireTime*(user: User): DateTime {.base.} =
  user.credential.expireTime

method getUserName*(user: User): Option[string] {.base.} =
  if user.uname.len > 0: return some(user.uname)

method getUserName*(req: jester.Request): string {.base.} =
  let token = req.cookies["torci"]
  for user in userList.users:
    if user.getToken == token:
      return user.uname

proc getUserName*(token: string): Option[string] =
  for user in userList.users:
    if user.getToken == token:
      return some(user.uname)

proc newExpireTime(): DateTime =
  result = getTime().utc + initTimeInterval(hours = 1)

proc token(user: var User, token: string) = 
  user.credential.token = token
  user.credential.expireTime = newExpireTime()

proc username(user: var User, username: string) =
  user.uname = username

proc add(user: User) =
  userList.users.add(user)

proc delete(index: int) =
  userList.users.delete(index)

method isExpired(user: User): bool {.base.} = 
  let now = getTime().utc
  if now > user.getExpireTime:
    return true

method isExpired(expire: DateTime): bool {.base.} = 
  let now = getTime().utc
  if now > expire:
    return true

method isLoggedIn*(req: jester.Request): bool {.base.} =
  if not req.cookies.hasKey("torci"): return
  let userToken = req.cookies["torci"]
  for i, user in userList.users:
    if user.isExpired:
      i.delete
      return false

    elif user.getToken == userToken:
      return true

# method isValidUser*(req: jester.Request): bool {.base.} =
#   if (req.isLoggedIn) and (req)

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

proc makeSalt(): string =
  # Creates a salt using a cryptographically secure random number generator.
  #
  # Ensures that the resulting salt contains no ``\0``.
  try:
    result = devRandomSalt()
  except IOError:
    result = randomSalt()

  var newResult = ""
  for i in 0 ..< result.len:
    if result[i] != '\0':
      newResult.add result[i]
  return newResult

proc makeSessionKey(): string =
  # Creates a random key to be used to authorize a session.
  let random = makeSalt()
  return bcrypt.hash(random, genSalt(8))
# The end of [https://github.com/nim-lang/nimforum/blob/master/src/auth.nim] code

proc splitShadow(str: string): seq[string] =
  let
    first = str.split("$")
    second = first[3].split(":")
  result = first 
  result[3] = second[0]

# proc getUsername*(r: jester.Request): Future[string] {.async.} =
#   let token = r.cookies["torci"]
#   try:
#     for v in userList.users:
#       if v.getToken == token:
#         return v.uname
  
#   except:
#     return

proc login*(username, password: string): Future[Result[tuple[token: string, expire: DateTime], string]] {.async.} =

  # Generate password hash using openssl cli
  # let 
  #   shadowCmd = &"sudo cat /etc/shadow | grep \"{username}\""
  #   shadowOut = execCmdEx(shadowCmd).output
  #   shadowV = splitShadow(shadowOut)
  #   passwdCmd = &"openssl passwd -{shadowV[1]} -salt \"{shadowV[2]}\" \"{password}\""
  #   spawnPasswd = execCmdEx(passwdCmd).output

  if username.len == 0: return err("Please set a username")
  elif password.len == 0: return err("Please set a password")
  
  try:
    let
      shadow = getShadow(cstring username)
      splittedShadow = splitShadow($shadow.passwd)
      crypted: string = $crypt(cstring password, cstring(&"${splittedShadow[1]}${splittedShadow[2]}"))
    # var passwdV = spawnPasswd.split("$")
    # passwdV[3] = passwdV[3].splitWhitespace[0]
    
    if $shadow.passwd == crypted:
      let
        token = makeSessionKey()
      var user = User.new 
      user.token(token)
      user.username(username)
      user.add
      let expire = user.getExpireTime
      result.ok (token, expire)

  except OSError:
    result.err "Invalid username or password"

  except: result.err "Something went wrong" 

proc logout*(req: Request): Future[bool] {.async.} =
  if not req.cookies.hasKey("torci"): return
  let userToken = req.cookies["torci"]
  for i, user in userList.users:
    if userToken == user.getToken:
      i.delete
      return true

template loggedIn*(node: untyped) =
  if request.isLoggedIn:
    node
  else:
    redirect "/login"

template notLoggedIn*(node: untyped) =
  if not request.isLoggedIn:
    node
  else:
    redirect "/"