import options, asyncdispatch
import jester
import tabs, impl_status
import ".." / [ types, notice ]
import ../ views / [ temp, status ]
import ".." / lib / [ session, sys, tor, wirelessManager ]
# import sugar

export status, impl_status

proc routingStatus*() =
  router status:

    before "/io":
      resp "Loading"

    get "/io":
      loggedIn:
        respIO

    post "/io":
      loggedIn:
        let notifies = await postIO(request)
        if notifies.isSome:
          respIO(notifies.get)
        redirect "/io"