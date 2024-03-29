FROM nimlang/nim:alpine as nim
EXPOSE 1984

RUN USER=root apk --no-cache add libsass-dev libffi-dev pcre-dev openssl-dev openssh-client openssl sudo tor wpa_supplicant dhcpcd openrc bsd-compat-headers

COPY . /src/torci
WORKDIR /src/torci
# create hostapd environment
RUN mkdir /etc/hostapd
RUN curl -o "/etc/hostapd/hostapd.conf" -A "Mozilla/5.0 (Windows NT 10.0; rv:98.0) Gecko/20100101 Firefox/91.0" https://raw.githubusercontent.com/radio24/TorBox/master/etc/hostapd/hostapd.conf \
    && cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.tbx

# add torbox user
RUN adduser --disabled-password --gecos "" torbox && echo "torbox:torbox" | chpasswd

RUN nimble build -d:release -y && nimble scss
CMD ["./torci"]