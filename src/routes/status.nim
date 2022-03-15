import options, asyncdispatch
import jester
import impl_status
import ../ views / [ temp, status ]
import ".." / lib / [ session, sys, wirelessManager ]
import ../ lib / tor / tor
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
        # await doTorRequest(request)
        let ret = await doTorRequest(request)
        if ret.isSome:
          resp ret.get

        redirect "/io"
        # let notifies = await postIO(request)
        # if notifies.isSome:
        #   respIO(notifies.get)
        # redirect "/io"