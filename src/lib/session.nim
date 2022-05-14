import std / [
  times, random,
  strutils
]
import jester
import redis
import bcrypt
import results, resultsutils
import clib / [ c_crypt, shadow ]
import crypt
when defined(debug):
  import std / terminal

# method username*(req: jester.Request): string {.base.} =
#   let token = req.cookies["torci_token"]
#   for user in userList.users:
#     if user.token == token:
#       return user.uname

proc newExpireTime(): DateTime =
  result = getTime().utc + initTimeInterval(hours = 1)

# method isExpired(user: User): bool {.base.} = 
#   let now = getTime().utc
#   if user.expire < now:
#     return true

# method isExpired(expire: DateTime): bool {.base.} = 
#   let now = getTime().utc
#   if expire < now:
#     return true

proc isLoggedIn*(req: jester.Request): Future[bool] {.async.} =
  if not req.cookies.hasKey("torci"): return
  let token = req.cookies["torci"]
  let red = await openAsync()
  return await red.exists(token)

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
    var f = system.open("/dev/urandom")
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

proc getUsername*(r: jester.Request): Future[string] {.async.} =
  let token = r.cookies["torci"]
  let red = await openAsync()
  return await red.get(token)

proc login*(username, password: string): Future[Result[tuple[token: string, expire: DateTime], string]] {.async.} =

  # Generate a password hash using openssl cli
  # let 
  #   shadowCmd = &"sudo cat /etc/shadow | grep \"{username}\""
  #   shadowOut = execCmdEx(shadowCmd).output
  #   shadowV = splitShadow(shadowOut)
  #   passwdCmd = &"openssl passwd -{shadowV[1]} -salt \"{shadowV[2]}\" \"{password}\""
  #   spawnPasswd = execCmdEx(passwdCmd).output

  if username.isEmptyOrWhitespace: return err("Please set a username")
  elif password.isEmptyOrWhitespace: return err("Please set a password")
  
  try:
    let
      spwd = getShadow(cstring username)
      # splittedShadow = splitShadow($shadow.passwd)
    #   ret = parseShadow($shadow.passwd)

    # ref: https://forum.nim-lang.org/t/8342
    if spwd.isnil: return err(username & " is not found")
    var shadow: Shadow
    # if ret.isErr:
    #   result.err ret.error
    #   return
    match readAsShadow($spwd.passwd):
      Ok(parse): shadow = parse
      Err(msg): return err(msg)

    let crypted: string = crypt(password, fmtSalt(shadow))
    when defined(debug):
      styledEcho(fgGreen, "Started login...")
      styledEcho(fgGreen, "[passwd] ", $spwd.passwd)
      styledEcho(fgGreen, "[Generated passwd] ", crypted)
    # var passwdV = spawnPasswd.split("$")
    # passwdV[3] = passwdV[3].splitWhitespace[0]
    
    if $spwd.passwd == crypted:
      let
        token = makeSessionKey()
        red = await openAsync()
      discard await red.setEx(token, 3600, username)
      result.ok (token, newExpireTime())

  except OSError as e: return err(e.msg)
  except IOError as e: return err(e.msg)
  except ValueError as e: return err(e.msg)
  except KeyError as e: return err(e.msg)
  except RedisError as e: return err(e.msg)
  except CatchableError as e: return err(e.msg)
  except NilAccessDefect as e: return err(e.msg)
  except: result.err "Something went wrong" 

proc logout*(req: Request): Future[bool] {.async.} =
  if not req.cookies.hasKey("torci"): return
  let token = req.cookies["torci"]
  let red = await openAsync()
  let loggedIn = await red.exists(token)
  if loggedIn:
    let del = await red.del(@[token])
    if del == 1: return true
    else: return false

template loggedIn*(node: untyped) =
  if await request.isLoggedIn:
    node
  else:
    redirect "/login"

template notLoggedIn*(node: untyped) =
  if not await request.isLoggedIn:
    node
  else:
    redirect "/"