# Troubleshooting: Zigbee, Thread und Matter unter Home Assistant Container

## Ziel

Dieser Leitfaden enthält wiederverwendbare Prüfpfade für:

- Sonoff Zigbee-Koordinator
- Zigbee2MQTT
- Mosquitto
- SkyConnect als Thread-RCP
- OpenThread Border Router
- Python Matter Server
- Home-Assistant-Integrationen
- serverseitiges Matter-Commissioning

---

## Schnellübersicht

```bash
docker ps -a
docker logs --tail=100 zigbee2mqtt
docker logs --tail=100 mosquitto
docker logs --tail=100 otbr
docker logs --tail=100 matter-server
```

```bash
ss -ltnp | grep -E ':(1883|8080|8081|5580)\b'
```

```bash
ls -l /dev/serial/by-id/
```

---

## 1. USB-Adapter wird nicht gefunden

### Host prüfen

```bash
lsusb
sudo dmesg | tail -50
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
ls -l /dev/serial/by-id/
```

### Container prüfen

```bash
docker exec zigbee2mqtt ls -l /dev/zigbee
docker exec otbr ls -l /dev/thread /dev/net/tun
```

### Typische Ursache

Der Host-Pfad und der Pfad im Container werden verwechselt.

```yaml
devices:
  - /dev/serial/by-id/<HOST_DEVICE>:/dev/zigbee
```

Die Anwendung muss `/dev/zigbee` verwenden, nicht den Host-Pfad.

---

## 2. Zigbee2MQTT startet nicht

```bash
docker logs --tail=200 zigbee2mqtt
```

Prüfen:

```yaml
serial:
  port: /dev/zigbee
  adapter: zstack
```

Häufige Ursachen:

- falscher Containerpfad
- anderer Prozess verwendet den Dongle
- ZHA greift auf denselben Adapter zu
- MQTT-Broker nicht erreichbar
- beschädigte oder unvollständige `configuration.yaml`

Konkurrierenden Zugriff prüfen:

```bash
sudo lsof /dev/serial/by-id/<SONOFF_BY_ID>
```

---

## 3. MQTT-Verbindung wird abgelehnt

Fehler:

```text
ECONNREFUSED 127.0.0.1:1883
```

Prüfen:

```bash
docker ps --filter name=mosquitto
ss -ltnp | grep ':1883'
docker logs --tail=100 mosquitto
```

Test:

```bash
mosquitto_sub -h 127.0.0.1 -t test -v
```

In einem zweiten Terminal:

```bash
mosquitto_pub -h 127.0.0.1 -t test -m hello
```

Wichtig: Zigbee2MQTT startet keinen eigenen MQTT-Broker.

---

## 4. Zigbee2MQTT-Weboberfläche nicht erreichbar

Lokal prüfen:

```bash
curl -v http://127.0.0.1:8080
ss -ltnp | grep ':8080'
```

Konfiguration:

```yaml
frontend:
  enabled: true
  port: 8080
```

Firewall:

```bash
sudo ufw status numbered
```

Beispiel für LAN-Freigabe:

```bash
sudo ufw allow from 192.168.88.0/24 to any port 8080 proto tcp
```

Bei `network_mode: host` erscheinen keine Docker-Portmappings. Das ist normal.

---

## 5. Home Assistant akzeptiert MQTT-Adresse nicht

Wenn die Oberfläche Host und Port getrennt abfragt:

```text
Host: 192.168.88.106
Port: 1883
```

Nicht:

```text
mqtt://192.168.88.106
```

---

## 6. OTBR-Container ist `Up`, Agent läuft aber nicht

```bash
docker exec otbr ps aux
docker logs --tail=200 otbr
```

Warnsignal:

```text
otbr-agent exited with code 5
```

oder:

```text
No such file or directory
```

Tatsächliche Variablen prüfen:

```bash
docker inspect otbr \
  --format '{{range .Config.Env}}{{println .}}{{end}}' |
  grep '^OT_'
```

Erwartet:

```text
OT_RCP_DEVICE=spinel+hdlc+uart:///dev/thread?uart-baudrate=460800&uart-flow-control
OT_INFRA_IF=eno1
OT_THREAD_IF=wpan0
```

Startskript des Images prüfen:

```bash
docker exec otbr cat /etc/s6-overlay/s6-rc.d/otbr-agent/run
```

Compose-Änderung anwenden:

```bash
docker compose config --quiet
docker compose up -d --force-recreate --no-deps otbr
```

Ein `docker restart otbr` übernimmt keine geänderte Compose-Konfiguration.

---

## 7. OTBR ist erreichbar, Thread steht auf `disabled`

```bash
docker exec otbr ot-ctl state
docker exec otbr ot-ctl dataset active -x
curl -sS http://127.0.0.1:8081/node
```

Möglicher Zustand vor der Home-Assistant-Einrichtung:

```text
disabled
Error 23: NotFound
```

Wenn die REST-API funktioniert, OTBR in Home Assistant hinzufügen:

```text
http://127.0.0.1:8081
```

Das Dataset nicht vorschnell manuell überschreiben.

---

## 8. Thread-Netzwerk ist aktiv

```bash
docker exec otbr ot-ctl state
```

Erwartet bei einem einzelnen neuen Netz:

```text
leader
```

```bash
curl -sS http://127.0.0.1:8081/node
```

Erwartete Merkmale:

- `state` ist aktiv
- `routerCount` ist mindestens 1
- `networkName` enthält kein Default-Platzhalternetz
- Leader-Daten sind gesetzt

Das aktive Dataset niemals veröffentlichen.

---

## 9. Matter-Server bleibt auf `Created`

```bash
docker inspect matter-server \
  --format 'Status={{.State.Status}} Error={{.State.Error}}'
```

Fehler:

```text
container otbr has no healthcheck configured
```

Root Cause:

```yaml
condition: service_healthy
```

ohne OTBR-Healthcheck.

Fix:

```yaml
depends_on:
  otbr:
    condition: service_started
```

---

## 10. Matter-Server ist gestartet, aber nicht erreichbar

```bash
ss -ltnp | grep ':5580'
```

Aus Home Assistant:

```bash
docker exec homeassistant python3 -c \
'import socket; s=socket.create_connection(("127.0.0.1",5580),5); print("ok"); s.close()'
```

Matter-URL in Home Assistant:

```text
ws://127.0.0.1:5580/ws
```

---

## 11. Matter-Server hat kein Bluetooth

Host:

```bash
bluetoothctl show
rfkill list bluetooth
```

Container:

```bash
docker exec matter-server \
  test -S /run/dbus/system_bus_socket \
  && echo "D-Bus vorhanden"
```

Compose:

```yaml
volumes:
  - /run/dbus:/run/dbus:ro
```

```yaml
command: >-
  --storage-path /data
  --paa-root-cert-dir /data/credentials
  --primary-interface eno1
  --bluetooth-adapter 0
  --port 5580
```

Manuellen Scan beenden:

```bash
bluetoothctl scan off
```

---

## 12. Mobile App meldet „kein WLAN“

Mögliche Ursachen:

- alternative Android-Variante
- GrapheneOS-/Profil-Isolation
- VPN blockiert LAN oder Multicast
- Always-on-VPN mit „Verbindungen ohne VPN blockieren“
- Companion-App läuft in einem anderen Profil als Google Play Services
- Standort-/Nearby-Berechtigungen fehlen

Prüfen:

- funktioniert Home Assistant im Browser desselben Profils?
- ist Proton VPN vollständig getrennt?
- ist „Verbindungen ohne VPN blockieren“ deaktiviert?
- wurden Thread-Zugangsdaten synchronisiert?
- wird das Gerät von der Google-Matter-Oberfläche per BLE erkannt?

Wenn das Gerät per BLE erkannt wird, die HA-Oberfläche aber dauerhaft „kein WLAN“ meldet, ist dies kein Beweis für einen Fehler von OTBR oder Matter Server.

---

## 13. Serverseitiges Matter-over-Thread-Commissioning

Voraussetzungen:

- OTBR aktiv
- Thread-Dataset vorhanden
- Matter Server erreichbar
- Bluetooth im Matter-Container verfügbar
- Gerät im Pairing-Modus
- Gerät nahe am EliteDesk
- Matter-Einrichtungscode vorhanden

Start:

```bash
cd /opt/docker/homeassistant/matter
./commission-thread-device.sh
```

Parallel:

```bash
docker logs -f matter-server
```

```bash
watch -n 2 'docker exec otbr ot-ctl child table'
```

---

## 14. Gerät wurde bereits teilweise eingerichtet

Nach fehlgeschlagenen Versuchen:

- Gerät nach Herstelleranleitung vollständig zurücksetzen
- Commissioning-Fenster erneut aktivieren
- konkurrierende Controller vermeiden
- Bluetooth-Abstand reduzieren
- Matter-Code erneut sorgfältig eingeben

Der manuelle Matter-Code wird ohne Bindestriche an die API übergeben. Das bereitgestellte Skript entfernt Bindestriche und Leerzeichen automatisch.

---

## 15. Sichere Eskalationsreihenfolge

1. physischen Adapter und stabilen Gerätepfad prüfen
2. Gerät im Container prüfen
3. einzelnen Dienst und Logs prüfen
4. Listener und lokale Verbindung prüfen
5. Verbindung aus dem konsumierenden Container prüfen
6. Home-Assistant-Integration prüfen
7. erst danach Firmware, Netzwerk oder Dataset verändern

Nicht mehrere Ebenen gleichzeitig ändern.
