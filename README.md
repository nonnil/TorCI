# TorCI

TorCI is a Configuration Interface for [TorBox](https://github.com/radio24/torbox). It is implemented in the [Nim](https://nim-lang.org) programming language.

<b>WARNING: THIS IS A BETA VERSION, THEREFORE YOU MAY ENCOUNTER BUGS. IF YOU DO, OPEN AN ISSUE VIA OUR GITHUB REPOSITORY.</b>

## Features:

-   [x] No JavaScript
-   [x] No Terminal
-   [x] Mobile device friendly
-   [x] Small and Nimble binary
-   [x] Configure [TorBox](https://radio24/torbox) as easy as [OpenWRT](https://github.com/openwrt)'s [LuCI](https://github.com/openwrt/luci)

## WIP

-	[ ] Improving UI
-	[ ] All TorBox features support
-	[ ] HTTPS support

## Screenshots
![Login](login.png)
![Status](status.png)
![Bridges](bridges.png)
![Wireless](wireless.png)

## Installation

### Docker

To build and run TorCI in Docker

```bash
$ docker build -t torci:beta .
$ docker run --rm -d -p 1984:1984 torci:beta
# See debug logs
$ docker logs `CONTAINER_ID`
```

Reach the TorCI: `127.0.0.1:1984`

(The default username and password : `torbox`)

### Nimble

To compile the scss files, you need to install `libsass`. On Ubuntu and Debian, you can use `libsass-dev`.

```bash
$ git clone https://github.com/nonnil/torci
$ cd torci
$ nimble build
$ nimble scss
```

and Run:

```bash
$ sudo ./torci
```

Then access the following address with a browser:

```
http://0.0.0.0:1984
```
## SystemD
You can use the SystemD service (install it on `/etc/systemd/system/torci.service`)

To run TorCI via SystemD you can use this service file:

```ini
[Unit]
Description=front-end for TorBox
After=syslog.target
After=network.target

[Service]
Type=simple

User=root

WorkingDirectory=/home/torbox/torci
ExecStart=/home/torbox/torci/torci

Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
```
