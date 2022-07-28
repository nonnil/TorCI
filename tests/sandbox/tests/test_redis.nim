import std / [ times, unittest, asyncdispatch, nativesockets ]
import redis

converter toInt(x: int64): int = cast[int](x)

proc main() {.async.} =
  let client = await openAsync(port=7000.Port)

  let token = "randomness0"
  let strct = @[
    ("username", "Tor-chan")
  ]
  echo "is nil? ", await client.hGet(token, "username")

  let res = await client.setEx(token, 3, "Tor-chan")
  echo "res: ", res
  echo "username before expire: ", await client.get(token)
  echo "sleeping..."

  await sleepAsync(300)
  echo "username after expire: ", await client.get(token)

  # let res = await client.flushPipeline()
  # echo res
  # echo get

proc normal() {.async.} =
  let red = await openAsync(port=7000.Port)

  block:
    let res = await red.ping()
    echo res
    
  block:
    let res = await red.ping()
    echo res

  block:
    let res = await red.ping()
    echo res

  block:
    let res = await red.ping()
    echo res

proc pipe() {.async.} =
  let red = await openAsync(port=7000.Port)
  red.startPipelining()

  block:
    let res = await red.ping()
    echo res

  block:
    let res = await red.ping()
    echo res
  
  block:
    let res = await red.ping()
    echo res

  block:
    let res = await red.ping()
    echo res

  let flushed = await red.flushPipeline()
  echo flushed

suite "Redis":
  waitFor main()
  test "normal":
    waitFor normal()
  test "pipe":
    waitFor pipe()