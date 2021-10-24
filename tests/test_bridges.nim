import strutils, re

proc isValidObfs4(obfs4: string): bool =
  let splited = obfs4.splitWhitespace()
  if splited.len == 4:

    if (splited[0] != "obfs4") or 
    (not splited[1].match(re"(\d+\.){3}(\d+):\d+")) or
    (not splited[2].match(re".+")) or
    (not splited[3].match(re"cert=.+")) or 
    (not splited[4].match(re"iat-mode=\d{1}")):
      return false

    else:
      return true
    
block:
  assert isValidObfs4("obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0") == true
  assert isValidObfs4("obfs4 0.0.0:999 cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg") == false