FROM debian:bullseye-slim as bullseye
ENV DEBIAN_FRONTEND=noninteractive
# ENV PATH="$PATH:$HOME/.nimble/nim/bin:$HOME/.nimble/bin"
# ENV PATH=$PATH:$HOME/.nimble/nim/bin:$HOME/.nimble/bin
# ENV PATH=$PATH:$HOME/.nimble/nim/bin:$HOME/.nimble/bin
RUN dpkg --add-architecture armhf && \
apt update && \
apt install -y build-essential openssl git curl \
binutils-arm-linux-gnueabi \
gcc-arm-linux-gnueabihf \
hostapd wpasupplicant && \
apt install -y libcrypt-dev:armhf

# install nim-lang binaries
RUN curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y
# RUN echo "export PATH=$PATH:$HOME/.nimble/nim/bin:$HOME/.nimble/bin" >> /root/.bashrc

# install dependencies for TorCI
WORKDIR /src/torci

CMD \
export PATH="${PATH}":$HOME/.nimble/nim/bin:$HOME/.nimble/bin && \
nimble test
# CMD ["nimble", "test"]