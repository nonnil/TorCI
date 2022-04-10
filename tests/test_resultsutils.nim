import std / [ unittest ]
import results
import ../ src / resultsutils

suite "resultsutils":
  test "test match macro":
    func example(): Result[string, string] =
      ok("something Ok")

    match example():
      Ok(someOk):
        echo someOk
        check:
          someOk == "something Ok"
      Err(someErr):
        check:
          someErr == "err msg"

    let msg = match example():
      Ok(someOk):
        "ok msg"
      Err(someErr):
        "err msg"
    
    check:
      msg == "ok msg"
  
  type R = Result[string, string]
  test "test `ok`":
    func returnOk(): R =
      ok("something ok")

    withResult returnOk():
      ok msg:
        check:
          msg == "something ok"
      err _:
        echo("withResult fail")

  test "test `err`":
    func returnErr(): Result[void, string] =
      err("something err")

    withResult returnErr():
      ok _:
        echo("withResult fail")
      
      err msg:
        check:
          msg == "something err"
        
  # test "test bracket":
  #   func first(): Result[void, string] =
  #     ok()

  #   func second(): Result[string, void] =
  #     err()

  #   func third(): Result[void, string] =
  #     ok()

  #   withResult [ first(), second(), third() ]:
  #     ok [ _, msg, _ ]:
  #       check:
  #         msg.len == 0

  #     err [ one, _, three ]:
  #       check:
  #         one.len == 0
  #         three.len == 0