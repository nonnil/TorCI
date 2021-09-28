import karax/[karaxdsl, vdom]

proc renderLogin*(): VNode =
  buildHtml(tdiv(class="content")):
    tdiv(class="login-pane"):
      tdiv(class="login-header"):
        img(class="logo", src="/images/torbox.png", alt="TorBox")
      tdiv(class="form-box"):
        tdiv(class="login-text"): text "Log Into TorBox"
        form(`method`="post", action="/login", enctype="multipart/form-data", class=""):
          tdiv(class="form-section username"):
            label(class=""):text "Username"
            input(`type`="text", `required`="", name="username", placeholder="torbox", class="inp")
          tdiv(class="form-section username"):
            label(class=""):text "Password"
            input(`type`="password", `required`="", name="password", class="inp")
          tdiv(class="login-btn"):
            button(`type`="submit", name="loginBtn", class=""):text "Login"