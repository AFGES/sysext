#!/bin/ash
#
# Build script helper for lldpd sysext.
# This script runs inside an ephemeral alpine container.
# It builds a static lldpd and exports the binaries to a bind-mounted volume.
#
set -euo pipefail

version="$1"
export_user_group="$2"

apk --no-cache add \
        bsd-compat-headers \
        build-base \
        curl \
        libevent-dev \
        libevent-static \
        linux-headers

cd /opt

curl -fsSL --retry 5 -o lldpd.tar.gz \
  "https://github.com/lldpd/lldpd/releases/download/${version}/lldpd-${version}.tar.gz"
tar xf lldpd.tar.gz
cd "lldpd-${version}"

./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --runstatedir=/run \
    --disable-shared \
    --enable-static \
    --without-snmp \
    --without-readline \
    --with-privsep-user=_lldpd \
    --with-privsep-group=_lldpd \
    --with-privsep-chroot=/run/lldpd

make LDFLAGS=-all-static
make DESTDIR=/install_root install

# The sysext only ships /usr; config and state live in /etc, /var and /run.
rm -rf /install_root/etc \
       /install_root/run \
       /install_root/var \
       /install_root/usr/share \
       /install_root/usr/include \
       /install_root/usr/lib
chmod -R u+rwX,go+rX /install_root
chown -R "$export_user_group" /install_root
