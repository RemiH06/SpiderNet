#!/usr/bin/env bash
# Instala o actualiza AdGuard Home como servicio de systemd, sin root.
# Uso: sudo ./install.sh <dir-del-sitio>   (el directorio lleva dns.env y,
# opcional, excepciones.txt; ver examples/bakery/)
set -euo pipefail

VERSION=v0.107.79
SITE=${1:?Uso: sudo ./install.sh <dir-del-sitio>}
HERE=$(cd "$(dirname "$0")" && pwd)
BIN_DIR=/opt/adguardhome
DATA=/var/lib/adguardhome
SVC_USER=adguardhome

[[ $EUID -eq 0 ]] || { echo "Correr con sudo" >&2; exit 1; }
[[ -f $SITE/dns.env ]] || { echo "No existe $SITE/dns.env" >&2; exit 1; }

set -a
# shellcheck source=/dev/null
. "$SITE/dns.env"
set +a
for v in SPIDERNET_LAN_IP SPIDERNET_ADMIN_PORT SPIDERNET_ADMIN_USER SPIDERNET_ADMIN_PASSWORD_HASH; do
  [[ -n ${!v:-} ]] || { echo "Falta $v en $SITE/dns.env" >&2; exit 1; }
done
# Sin comillas simples en dns.env, el shell se come los $ del hash.
[[ $SPIDERNET_ADMIN_PASSWORD_HASH == '$2'* ]] || {
  echo "SPIDERNET_ADMIN_PASSWORD_HASH no parece bcrypt: ¿le faltan las comillas simples?" >&2; exit 1; }

case $(uname -m) in
  aarch64) ARCH=arm64 ;;
  x86_64) ARCH=amd64 ;;
  *) echo "Arquitectura no soportada: $(uname -m)" >&2; exit 1 ;;
esac

# Binario fijo a VERSION, verificado contra los checksums de la release.
if ! "$BIN_DIR/AdGuardHome" --version 2>/dev/null | grep -q "$VERSION"; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  base=https://github.com/AdguardTeam/AdGuardHome/releases/download/$VERSION
  tarball=AdGuardHome_linux_$ARCH.tar.gz
  curl -fsSL -o "$tmp/$tarball" "$base/$tarball"
  curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt"
  (cd "$tmp" && grep " ./$tarball\$" checksums.txt | sha256sum -c -)
  tar -xzf "$tmp/$tarball" -C "$tmp"
  install -D -m 755 "$tmp/AdGuardHome/AdGuardHome" "$BIN_DIR/AdGuardHome"
fi

id -u "$SVC_USER" >/dev/null 2>&1 ||
  useradd --system --home-dir "$DATA" --shell /usr/sbin/nologin "$SVC_USER"
install -d -m 700 -o "$SVC_USER" -g "$SVC_USER" "$DATA"

# Excepciones: genéricas del repo + las del sitio. Sin comentarios (! o #).
SPIDERNET_USER_RULES=$(cat "$HERE/excepciones.txt" "$SITE/excepciones.txt" 2>/dev/null |
  grep -Ev '^[[:space:]]*([!#]|$)' | sed "s/'/''/g; s/^/  - '/; s/\$/'/" || true)
export SPIDERNET_USER_RULES

new=$DATA/AdGuardHome.yaml.new
envsubst '${SPIDERNET_LAN_IP} ${SPIDERNET_ADMIN_PORT} ${SPIDERNET_ADMIN_USER} ${SPIDERNET_ADMIN_PASSWORD_HASH} ${SPIDERNET_USER_RULES}' \
  < "$HERE/AdGuardHome.yaml.tmpl" > "$new"
chown "$SVC_USER:$SVC_USER" "$new"
chmod 600 "$new"
runuser -u "$SVC_USER" -- "$BIN_DIR/AdGuardHome" --check-config -c "$new" -w "$DATA" --no-check-update
mv "$new" "$DATA/AdGuardHome.yaml"

install -m 644 "$HERE/adguardhome.service" /etc/systemd/system/adguardhome.service
systemctl daemon-reload
systemctl enable adguardhome
systemctl restart adguardhome
systemctl --no-pager status adguardhome | head -5
