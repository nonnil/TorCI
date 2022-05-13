import std / [
  unittest,
  asyncdispatch, times, terminal
]
import redis
import results, resultsutils
import ../ ../ ../ src / lib / session {.all.}

suite "Login...":
  test "logged in...":
    # privateAccess()
    proc isLoggedIn(key: string): Future[bool] {.async.} =
      let red = await openAsync()
      return await red.exists(key)

    proc makeUser(token: string, name: string) {.async.} =
      let red = await openAsync()
      discard await red.setEx(token, 10, name)

    proc getUsername(token: string): Future[string] {.async.} =
      let red = await openAsync()
      return await red.get(token)

    let ses = makeSessionKey()
    waitFor makeUser(ses, "tor-chan")
    check: waitFor isLoggedIn(ses); "tor-chan" == waitFor getUsername(ses)

  test "try login":
    match waitFor login("tor-chan", "tor-chan"):
      Ok(login):
        styledEcho fgGreen, "  [Username] ", fgWhite, login.token
        styledEcho fgGreen, "  [Expire at] ", fgWhite, $login.expire
      Err(msg):
        styledEcho fgRed, "  [Error] ", fgWhite, msg