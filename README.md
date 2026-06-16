# AstroServers – Infraestructura Cloud Privada y Ciberseguridad
Proyecto académico del curso **Sistemas Operativos II** (Universidad Mariano Gálvez de Guatemala), enfocado en el diseño, configuración y asegurado de una infraestructura virtualizada con segmentación de redes, replicación de bases de datos y servicios web. Se realizo el  diseño de la arquitectura de red segura (DMZ, bastión, firewall), las reglas de iptables, la configuración de DHCP/Squid, y del análisis de riesgos basado en MAGERIT alineado a ISO/IEC 27001:2013.

## Arquitectura de red

```
                        INTERNET
                            |
                            |
                  +-------------------+
                  |     BASTIÓN       |
                  |   192.168.1.13    |
                  |  (enp0s3: WAN)    |
                  |  Firewall/NAT     |
                  |  iptables         |
                  +-------------------+
                   /                \
        enp0s8 /                      \ enp0s9
        10.10.10.1/24                  20.10.10.1/24
              |                              |
   +---------------------+        +----------------------+
   |   RED INTERNA       |        |        DMZ           |
   |   (Cliente)         |        |                      |
   |  10.10.10.0/24      |        |   20.10.10.0/24      |
   |                     |        |                      |
   |  Cliente:           |        |  - Nginx (proxy      |
   |   10.10.10.26       |        |    reverso)          |
   |  - MySQL (master)   |        |  - Apache2 (sitio    |
   |    server-id=1      |<------>|    Astroservers)     |
   |  - DHCP server      |  3306  |  - MySQL (master)    |
   |    (10.10.10.26-50) |  Repli-|    server-id=2       |
   |  - Webmin           |  cación|  - SquirrelMail      |
   |                     |  M-M   |    (SMTP/POP3/IMAP)  |
   |                     |        |  - Webmin            |
   |                     |        |  - DHCP server       |
   |                     |        |    (20.10.10.26-50)  |
   +---------------------+        +----------------------+

         Squid (proxy transparente, SSL bump)
         corriendo en el Bastión, intercepta
         tráfico 80/443 desde enp0s8 y enp0s9 con certificados instalados 
         en firefox de ambas maquinas. 
```

## Acceso remoto (SSH vía bastión)

Todo el acceso externo pasa por el bastión, que se redirige según el puerto:

| Puerto externo (bastión) | Destino | Servicio |
|---|---|---|
| 22 | Lampaio (20.10.10.28) | SSH |
| 23 | Cliente (10.10.10.26) | SSH |
| 24 | DMZ (20.10.10.26) | SSH |
| 26 | Bastión (192.168.1.13) | SSH propio |
| 10001 | Cliente | Webmin |
| 10002 | DMZ | Webmin |
| 80 / 1898 | Lampaio | HTTP / app |
| 25, 110, 143 | DMZ | SMTP, POP3, IMAP (correo) |

## Replicación de base de datos MySQL Master-Master

- **Cliente** (server-id=1) y **DMZ** (server-id=2) replican bidireccionalmente la base umg_didactica.
- Tráfico de replicación en el puerto 3306, permitido entre enp0s8 (red interna) y enp0s9 (DMZ) en el firewall.
- Acceso externo vía ODBC: puerto 3306 Cliente, puerto 3307 DMZ (redireccionado desde el bastión).
- slave_skip_errors configurado para tolerar conflictos típicos de replicación bidireccional (1062, 1396, 1410).

## Proxy transparente (Squid y SSL Bump)

Squid corre en el bastión e intercepta el tráfico HTTP/HTTPS de ambas redes mediante reglas de `iptables` REDIRECT:
- Puerto 80 → 3129 (intercept)
- Puerto 443 → 3130 (intercept, ssl-bump)

Incluye reglas adicionales de bloqueo a rangos de IP específicos (CDNs) como ejercicio práctico de filtrado de tráfico a nivel de red, complementando el filtrado realizado por Squid. Además se hizo la instalación de certificados en los navegadores de ambas redes para el funcionamiento del proxy 
transparente bloqueando y respetando las ACL´S descritas. 

## Seguridad y gestión de riesgos

- Pruebas de seguridad ejecutadas en entorno controlado siguiendo **PTES, OWASP WSTG, MITRE ATT&CK, NIST SP 800-115 y OSSTMM**.
- Reconocimiento activo/pasivo, identificación y análisis de vulnerabilidades, explotación de redes cableadas e inalámbricas.
- Evaluación básica de vulnerabilidades en entornos cloud (AWS, GCP).
- **Análisis de riesgos basado en MAGERIT**: 100 activos identificados, 26 escenarios de riesgo, alineado a controles de **ISO/IEC 27001:2013**.
- Consideración de marcos normativos PCI DSS y HIPAA en la elaboración de reportes de hallazgos.

## Tecnologías utilizadas
Linux (Ubuntu Server), Kali Linux, VirtualBox, iptables, Netplan/NetworkManager, MySQL (replicación Master-Master), Nginx, Apache2, SquirrelMail, Squid (proxy transparente con SSL bump), Webmin, isc-dhcp-server, MAGERIT, ISO/IEC 27001.
