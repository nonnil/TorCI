import std / unittest
import std / [strutils, re]
import std / [sha1, json]
import std / [httpclient, asyncdispatch]
import ../ src / lib / [binascii, bridges]
import ../ src / types
import std / nativesockets
import torrc_template

suite "Bridges validity":
  const
    o = "obfs4 122.148.194.24:993 07784768F54CF66F9D588E19E8EE3B0FA702711B cert=m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg iat-mode=0"
    m = "meek_lite 192.0.2.2:2 97700DFE9F483596DDA6264C4D7DF7641E1E39CE url=https://meek.azureedge.net/ front=ajax.aspnetcdn.com"
    s = "snowflake 192.0.2.3:1 2B280B23E1107BB62ABFC40DDCC8824814F80A72"
  
  let obfs4: Obfs4 = parseObfs4(o)
  let meekazure: Meekazure = parseMeekazure(m)
  let snowflake: Snowflake = parseSnowflake(s)

  test "obfs4 validity":
    check:
      obfs4.ipaddr == "122.148.194.24"
      obfs4.port == 993.Port
      obfs4.fingerprint == "07784768F54CF66F9D588E19E8EE3B0FA702711B"
      obfs4.cert == "m3jPGnUyZMWHT9Riioob95s1czvGs3HiZ64GIT3QbH/AZDVlF/YEXu/OtyYZ1eObKnTjcg"
      obfs4.iatMode == "0"
  
  test "meekazure validity":
    check:
      meekazure.ipaddr == "192.0.2.2"
      meekazure.port == 2.Port
      meekazure.fingerprint == "97700DFE9F483596DDA6264C4D7DF7641E1E39CE"

  test "snowflake validity":
    check:
      snowflake.ipaddr == "192.0.2.3"
      snowflake.port == 1.Port
      snowflake.fingerprint == "2B280B23E1107BB62ABFC40DDCC8824814F80A72"

suite "Check fingerprint of Tor bridges":
  test "Fingerprint hashing":
    let
      o4Fp = "07784768F54CF66F9D588E19E8EE3B0FA702711B"
      o4Hashed = "581674112383BEBF88E79C3328B71ADF79365B45"

      sfFp = "2B280B23E1107BB62ABFC40DDCC8824814F80A72" 
      sfHashed = "5481936581E23D2D178105D44DB6915AB06BFB7F"


      sfHash = secureHash(a2bHex(sfFp))
      o4Hash = secureHash(a2bHex(o4Fp))
      
    check:
      $sfHash == sfHashed
      $o4Hash == o4Hashed

suite "Request to Onionoo":
  proc isFound(fp: string): bool =
    const
      destHost = "https://onionoo.torproject.org/details?lookup="
      userAgent = "Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0"

    var client = newHttpClient(userAgent = userAgent)

    let res = client.get(destHost & fp)

    if res.code == Http200:
      let
        j = parseJson(res.body)
        b = j["bridges"]

      if b.len > 0:
        let hashedFP = b[0]{"hashed_fingerprint"}.getStr
        if fp == hashedFP: return true

  test "Get bridges data":
    const
      fp = "07784768F54CF66F9D588E19E8EE3B0FA702711B"
      hfp = "581674112383BEBF88E79C3328B71ADF79365B45"

    check:
      hfp.isFound()
      not fp.isFound()
      not "123456FF".isFound()

suite "Bridge actions":
  test "Activate obfs4":
    proc activateObfs4(torrc: string, kind: ActivateObfs4Kind): string =
      var rc = torrc
      rc = rc.replacef(re"#UseBridges\s(\d+)", "UseBridges $1")
      rc = rc.replacef(re"#UpdateBridgesFromAuthority\s(\d+)", "UpdateBridgesFromAuthority $1")
      rc = rc.replacef(re"#ClientTransportPlugin meek_lite,obfs4\s(.*)", "ClientTransportPlugin meek_lite,obfs4 $1")
      rc = rc.replacef(re"[^#]ClientTransportPlugin snowflake\s(.*)", "\n#ClientTransportPlugin snowflake $1")
      rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")
      rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")

      case kind
      of ActivateObfs4Kind.all:
        rc = rc.replacef(re"#Bridge obfs4\s(.*)", "Bridge obfs4 $1")
      
      of ActivateObfs4Kind.online:
        rc = rc.replacef(re"#Bridge obfs4\s(.*)", "Bridge obfs4 $1")

      of ActivateObfs4Kind.select:
        rc = rc.replacef(re"#Bridge obfs4\s(.*)", "Bridge obfs4 $1")

      return rc

    check:
      torrc_activated_obfs4 == torrc.activateObfs4(ActivateObfs4Kind.all)
  
  test "Deactivate obfs4":
    proc deactivateObfs4(torrc: string): string =
      var rc = torrc
      rc = rc.replacef(re"[^#]UseBridges\s(\d+)", "\n#UseBridges $1")
      rc = rc.replacef(re"[^#]UpdateBridgesFromAuthority\s(\d+)", "\n#UpdateBridgesFromAuthority $1")
      rc = rc.replacef(re"[^#]ClientTransportPlugin meek_lite,obfs4\s(.*)", "\n#ClientTransportPlugin meek_lite,obfs4 $1")
      rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")

      return rc

    check:
      torrc == torrc_activated_obfs4.deactivateObfs4()

  test "Activate meekazure":
    proc activateMeekazure(torrc: string): string =
      var rc = torrc

      rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")
      rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")
      rc = rc.replacef(re"[^#]ClientTransportPlugin snowflake\s(.*)", "\n#ClientTransportPlugin snowflake $1")
      rc = rc.replacef(re"#UseBridges\s(\d+)", "UseBridges $1")
      rc = rc.replacef(re"#UpdateBridgesFromAuthority\s(\d+)", "UpdateBridgesFromAuthority $1")
      rc = rc.replacef(re"#ClientTransportPlugin meek_lite,obfs4\s(.*)", "ClientTransportPlugin meek_lite,obfs4 $1")
      rc = rc.replacef(re"#Bridge meek_lite\s(.*)", "Bridge meek_lite $1")

      return rc

    check:
      torrc_activated_meekazure == torrc.activateMeekazure()

  test "Deactivate meekazure":
    proc deactivateMeekazure(torrc: string): string =
      var rc = torrc

      rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")
      rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")
      rc = rc.replacef(re"[^#]ClientTransportPlugin snowflake\s(.*)", "\n#ClientTransportPlugin snowflake $1")
      rc = rc.replacef(re"[^#]UseBridges\s(\d+)", "\n#UseBridges $1")
      rc = rc.replacef(re"[^#]UpdateBridgesFromAuthority\s(\d+)", "\n#UpdateBridgesFromAuthority $1")
      rc = rc.replacef(re"[^#]ClientTransportPlugin meek_lite,obfs4\s(.*)", "\n#ClientTransportPlugin meek_lite,obfs4 $1")
      rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")
    
      return rc

    check:
      torrc == torrc_activated_meekazure.deactivateMeekazure()

  test "Activate snowflake":
    proc activateSnowflake(torrc: string): string =
      var rc = torrc

      rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")
      rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")
      rc = rc.replacef(re"#UseBridges\s(\d+)", "UseBridges $1")
      rc = rc.replacef(re"#UpdateBridgesFromAuthority\s(\d+)", "UpdateBridgesFromAuthority $1")
      rc = rc.replacef(re"#ClientTransportPlugin snowflake\s(.*)", "ClientTransportPlugin snowflake $1")
      rc = rc.replacef(re"#Bridge snowflake\s(.*)", "Bridge snowflake $1")

      return rc

    check:
      torrc_activated_snowflake == torrc.activateSnowflake()

  test "Deactivate snowflake":
    proc deactivateSnowflake(torrc: string): string =
      var rc = torrc

      rc = rc.replacef(re"[^#]Bridge obfs4\s(.*)", "\n#Bridge obfs4 $1")
      rc = rc.replacef(re"[^#]Bridge meek_lite\s(.*)", "\n#Bridge meek_lite $1")
      rc = rc.replacef(re"[^#]UseBridges\s(\d+)", "\n#UseBridges $1")
      rc = rc.replacef(re"[^#]UpdateBridgesFromAuthority\s(\d+)", "\n#UpdateBridgesFromAuthority $1")
      rc = rc.replacef(re"[^#]ClientTransportPlugin snowflake\s(.*)", "\n#ClientTransportPlugin snowflake $1")
      rc = rc.replacef(re"[^#]Bridge snowflake\s(.*)", "\n#Bridge snowflake $1")

      return rc

    check:
      torrc == torrc_activated_snowflake.deactivateSnowflake()