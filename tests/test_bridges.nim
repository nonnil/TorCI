import strutils, re

proc isValidObfs4(obfs4: string): bool =
  let splitted = obfs4.splitWhitespace()
  if splitted.len == 5:
    if (splitted[0] != "obfs4") or 
    (not splitted[1].match(re"(\d+\.){3}(\d+):\d+")) or
    (not splitted[2].match(re".+")) or
    (not splitted[3].match(re"cert=.+")) or 
    (not splitted[4].match(re"iat-mode=\d{1}")):
      return false

    else:
      return true
    
block:
  assert isValidObfs4("obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0") == true
  assert isValidObfs4("obfs4 0.0.0:999 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0") == false
  assert isValidObfs4("obfs4 122.148.194.24:993 cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0") == false
  assert isValidObfs4("obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert= iat-mode=0") == false
  assert isValidObfs4("obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=19") == false