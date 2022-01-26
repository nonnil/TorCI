import options, asyncdispatch
import jester, results
import impl_status
import ".." / [ types, notice ]
import ../ views / [temp, status]
import ".." / lib / [session, sys, tor, wirelessManager]
# import sugar

export status, impl_status

proc routingStatus*() =
  router status:

    before "/io":
      resp "Loading"

    get "/io":
      let user = await getUser(request)
      if user.isLoggedIn:
        respIO
      else:
        redirect "/login"

    post "/io":
      let user = await getUser(request)
      if user.isLoggedIn:
        let notifies = await postIO(request)
        if notifies.isSome:
          respIO(notifies.get)
        redirect "/io"
      redirect "/login"