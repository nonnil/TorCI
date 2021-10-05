FROM nimlang/nim:alpine as nim
MAINTAINER nilnilnilnil@protonmail.com
EXPOSE 1984

RUN USER=root apk --no-cache add libsass-dev libffi-dev pcre-dev openssl-dev openssh-client openssl sudo tor wpa_supplicant dhcpcd openrc bsd-compat-headers

COPY . /src/torci
WORKDIR /src/torci
# create hostapd environment
RUN mkdir /etc/hostapd
RUN curl -A "Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0" -o "/etc/hostapd/hostapd.conf" https://raw.githubusercontent.com/radio24/TorBox/master/etc/hostapd/hostapd.conf \
    && cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.tbx

# add torbox user
RUN adduser --disabled-password --gecos "" torbox && echo "torbox:torbox" | chpasswd

RUN nimble build -y && nimble scss
CMD ["./torci"]