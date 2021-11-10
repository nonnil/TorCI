import std/unittest
import strutils, re

suite "Check bridges validity":

  proc isValidObfs4(obfs4: string): bool =
    let splitted = obfs4.splitWhitespace()
    if splitted.len == 5:

      if (splitted[0] == "obfs4") and
      (splitted[1].match(re"(\d+\.){3}(\d+):\d+")) and
      (splitted[2].match(re".+")) and
      (splitted[3].match(re"cert=.+")) and
      (splitted[4].match(re"iat-mode=\d")):
        return true

      else:
        return false

  proc isValidSnowflake(snowflake: string): bool =
    let s = snowflake.splitWhitespace()
    if s.len == 2:
      
      if (s[0].match(re"(\d+\.){3}(\d+):\d+")) and
      (s[1].match(re".+")):
        return true
      
      else:
        return false
      
  test "obfs4 validity":
    check:
      isValidObfs4("obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0")
      not isValidObfs4("obfs4 0.0.0:999 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0")
      not isValidObfs4("obfs4 122.148.194.24:993 cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0")
      not isValidObfs4("obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert= iat-mode=0")
      not isValidObfs4("obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=g")

  test "snowflake validity":
    let strs = splitWhitespace("#Bridge snowflake 192.0.2.3:1 2B280B23E1107BB62ABFC40DDCC8824814F80A72", 2)
    check:
      isValidSnowflake(strs[2])
      not isValidSnowflake(strs[1])