# DNS con bloqueo de anuncios

AdGuard Home nativo (un binario y un servicio de systemd, sin root), con la configuración en este repo. Pensado para dos Raspberry Pi como DNS primario y secundario, repartidos por el DHCP del router.

## Instalar en cada Pi

1. Darle a la Pi una IP fija fuera del rango del DHCP del router.
2. Clonar el repo y crear la configuración del sitio (gitignorada):
   ```bash
   git clone https://github.com/RemiH06/SpiderNet.git && cd SpiderNet
   mkdir -p sites && cp -r examples/bakery sites/mi-red
   mv sites/mi-red/dns.env.example sites/mi-red/dns.env
   chmod 600 sites/mi-red/dns.env   # luego llenar los valores
   ```
3. Si la Pi tiene firewall, permitir el 53 (UDP y TCP) desde la LAN.
4. `sudo ./services/dns/install.sh sites/mi-red`
5. Probar desde otra máquina: `nslookup doubleclick.net <ip-de-la-pi>` debe dar `0.0.0.0`, y `nslookup wikipedia.org <ip-de-la-pi>` una IP real.
6. Panel: escucha solo en `127.0.0.1`. Para verlo desde otra máquina, `sudo tailscale serve --bg --https=<puerto> http://127.0.0.1:<puerto>`, o un túnel SSH.

Para actualizar listas, excepciones o versión: editar el repo, `git pull` en la Pi y volver a correr `install.sh`. Lo que se cambie desde el panel se pierde en ese paso.

## Excepciones

`excepciones.txt` (genéricas) y `sites/<red>/excepciones.txt` (propias). Sintaxis de AdGuard: `@@||dominio^` deja pasar el dominio. Cada excepción lleva un comentario de qué rompía.

## Límites

Ver [docs/limites-dns.md](../../docs/limites-dns.md): qué no puede bloquear un DNS y qué dispositivos se lo brincan.
