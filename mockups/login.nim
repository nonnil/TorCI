import jester
import ../ tests / server / server
import ".." / src / views / login 
import ".." / src / renderutils

router loginPage:
  get "/":
    resp renderFlat(renderLogin(), "Login")

serve(loginPage, 1984.Port)