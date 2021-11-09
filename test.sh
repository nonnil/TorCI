# TOR_SERVICE=$(curl --socks5 127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs)
# echo $TOR_SERVICE
checkTor()
{
TOR_SERVICE=$(curl --socks5 127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs)
echo $TOR_SERVICE
IsTor=$(curl --socks5 192.168.42.1:9050 --socks5-hostname 192.168.42.1:9050 -m 5 -s https://check.torproject.org/api/ip | grep -oP '"IsTor"\s*:\s*\K\w+')
if [ $IsTor = true ]; then
  echo "Tor is working"
else
  echo "Tor doesn't work..."
fi
}

checkTor