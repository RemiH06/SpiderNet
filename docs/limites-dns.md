# Límites del bloqueo por DNS

El DNS solo decide si un nombre de dominio se resuelve. No ve el contenido ni la ruta de una página, así que no distingue un anuncio de un video que viene del mismo dominio.

## Lo que no se bloquea

- **Anuncios de YouTube e Instagram (y en general de Meta y Google en sus apps).** Se sirven desde los mismos dominios que el contenido. Bloquear el dominio rompe la app; dejarlo pasa los anuncios. Para eso hace falta un bloqueador dentro del navegador (uBlock Origin) o un cliente alternativo.
- **Anuncios insertados en el mismo archivo** (por ejemplo, patrocinios dentro de un video o un podcast).

## Quién se brinca el DNS de la red

| Caso | Por qué | Qué se puede hacer |
|---|---|---|
| Chrome o Edge con "DNS seguro" en un proveedor personalizado | Resuelven por HTTPS directo con ese proveedor | Desactivarlo en el dispositivo. En modo automático, Chrome solo lo cifra si el DNS del sistema ya es un proveedor conocido, así que con el DNS de la red no se lo brinca |
| Firefox con DoH | Igual | La red responde al dominio canario `use-application-dns.net` (AdGuard lo hace) y Firefox desactiva su DoH automático. Si alguien lo activó a mano, no hay forma desde la red |
| DNS privado de Android con un host fijo (p. ej. `dns.google`) | Usa DNS sobre TLS (puerto 853) hacia ese host | Ponerlo en "Automático" o "Desactivado". Bloquear la salida al 853 en el router, si lo permite |
| iCloud Private Relay, VPNs, Tor | Todo el tráfico, DNS incluido, va cifrado a otro lado | Ninguna desde la red; es lo que deben hacer |
| Smart TVs y apps con DNS fijo en el código (p. ej. `8.8.8.8`) | Ignoran el DNS del DHCP | Redirigir el 53 saliente en el router (casi ningún router de proveedor lo permite) o la Pi como puerta de enlace |
| DNS por IPv6 que reparte el router | Si el router anuncia su propio DNS IPv6, los dispositivos pueden usarlo en lugar de la Pi | Quitar o cambiar el DNS IPv6 en la configuración de LAN IPv6 del router |

## Redundancia

Las dos Pi van como DNS primario y secundario en el DHCP. Los dispositivos eligen entre los dos a su manera (no siempre el primario primero), así que **las dos deben tener la misma configuración**: si una se queda atrás, el bloqueo se vuelve intermitente.

No se agrega un DNS público como tercer servidor: daría respaldo, pero los dispositivos lo usarían por momentos y se brincarían el bloqueo.
