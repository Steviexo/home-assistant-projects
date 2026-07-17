# Incident und Migration: Zigbee, Thread und Matter auf Home Assistant Container

## Einordnung

Dieser Vorgang begann mit der Anschaffung eines Aqara Door and Window Sensor P2 für Matter-over-Thread.

Home Assistant lief bereits als Docker-Container auf einem HP EliteDesk. Der vorhandene SkyConnect wurde zu diesem Zeitpunkt für Zigbee verwendet. Ziel war, bestehende Zigbee-Geräte weiter zu betreiben und zusätzlich Matter-over-Thread zu ermöglichen, ohne Home Assistant auf eine neue Plattform zu migrieren.

---

## Kurzfassung

Die endgültige Lösung verwendet zwei getrennte Funkadapter:

- Sonoff Zigbee 3.0 USB Dongle Plus für Zigbee
- SkyConnect mit OpenThread-RCP-Firmware für Thread

Darüber laufen:

- Zigbee2MQTT
- Mosquitto
- OpenThread Border Router
- Python Matter Server
- Home Assistant Container

Mehrere Probleme mussten nacheinander gelöst werden:

1. Sonoff-Dongle korrekt identifizieren und stabil durchreichen
2. externen MQTT-Broker bereitstellen
3. UFW-Regeln für Weboberfläche und MQTT berücksichtigen
4. Home Assistant korrekt mit MQTT verbinden
5. OTBR mit den tatsächlich unterstützten Umgebungsvariablen starten
6. Matter-Server nicht auf einen nicht vorhandenen OTBR-Healthcheck warten lassen
7. Bluetooth in den Matter-Server durchreichen
8. mobile GrapheneOS-/VPN-Probleme durch serverseitiges Commissioning umgehen

Der Aqara P2 wurde anschließend erfolgreich direkt über Bluetooth des EliteDesk provisioniert und in Home Assistant eingebunden.

---

## Umgebung

### Host

- HP EliteDesk
- Linux
- Docker Compose
- Home Assistant als Container
- Netzwerkinterface: `eno1`
- lokaler Bluetooth-Adapter: `hci0`

### Funkadapter

- Sonoff Zigbee 3.0 USB Dongle Plus
- Home Assistant SkyConnect / Connect ZBT-1

### Dienste

- Home Assistant
- Zigbee2MQTT
- Eclipse Mosquitto
- OpenThread Border Router
- Python Matter Server

---

## Ausgangslage

Der SkyConnect war bereits für Zigbee im Einsatz. Für den Aqara P2 wurde Thread benötigt.

Die gewählte Architektur sollte vorhandene Hardware weiterverwenden, Zigbee und Thread gleichzeitig bereitstellen, keine Migration von Home Assistant auf HAOS, Yellow oder Green erfordern und lokal ohne proprietären Hersteller-Hub funktionieren.

---

## Phase 1 – Sonoff-Dongle und Zigbee

### Symptom

Der neu angeschlossene Sonoff-Dongle schien zunächst nicht in `lsusb` aufzutauchen.

### Analyse

Kernel-Logs zeigten:

```text
Product: Sonoff Zigbee 3.0 USB Dongle Plus
Manufacturer: ITead
cp210x converter now attached to ttyUSB1
```

`lsusb` erkannte:

```text
10c4:ea60 Silicon Labs CP210x UART Bridge
```

### Ergebnis

Der Dongle war funktionsfähig und wurde als `/dev/ttyUSB1` eingebunden.

### Dauerhafte Lösung

Nicht den dynamischen Pfad verwenden, sondern:

```text
/dev/serial/by-id/<SONOFF_BY_ID>
```

Im Container:

```text
/dev/zigbee
```

---

## Phase 2 – Zigbee2MQTT und MQTT

### Symptom

Zigbee2MQTT erkannte den Koordinator, beendete sich aber mit:

```text
MQTT failed to connect
connect ECONNREFUSED 127.0.0.1:1883
```

### Root Cause

Es lief kein MQTT-Broker.

Eine frühere Annahme, Zigbee2MQTT könne selbst einen eingebetteten Broker starten, war falsch. Zigbee2MQTT ist MQTT-Client und benötigt einen externen Broker.

### Fix

Eclipse Mosquitto als separaten Container einrichten.

Verifikation:

```bash
ss -ltnp | grep ':1883'
```

```bash
mosquitto_sub -h localhost -t test -v
mosquitto_pub -h localhost -t test -m hello
```

Ergebnis:

```text
test hello
```

### Home-Assistant-Fallstrick

In der Home-Assistant-MQTT-Maske wurden Host und Port getrennt abgefragt. Der Host musste ohne Schema eingetragen werden:

```text
192.168.88.106
```

Nicht:

```text
mqtt://192.168.88.106
```

---

## Phase 3 – UFW und Container-Ports

### Symptom

Die Zigbee2MQTT-Weboberfläche lauschte auf Port 8080, war aus dem LAN aber nicht erreichbar.

Prüfung:

```bash
ss -ltnp | grep ':8080'
```

zeigte einen Listener.

Lokal funktionierte der Dienst, aus dem Netzwerk jedoch nicht.

### Root Cause

UFW blockierte Port 8080.

### Fix

Port gezielt für das lokale Netz freigeben.

Beispiel:

```bash
sudo ufw allow from 192.168.88.0/24 to any port 8080 proto tcp
```

### Lesson Learned

Bei `network_mode: host` werden keine Docker-Portmappings benötigt. Die Host-Firewall bleibt jedoch vollständig wirksam.

---

## Phase 4 – Zigbee-Geräte migrieren

Ein neuer Zigbee-Koordinator bildet grundsätzlich ein eigenes Netzwerk.

Die bestehenden Geräte mussten auf den Sonoff-Koordinator migriert beziehungsweise erneut gepaart werden.

Wichtig:

- Gerät für Gerät migrieren
- alte Entitätsnamen dokumentieren
- Friendly Names gezielt setzen
- Automatisierungen nach der Migration prüfen
- Zigbee2MQTT-Datenverzeichnis sichern

---

## Phase 5 – OTBR startet mit falschen Standardwerten

### Symptom

Der OTBR-Container stand auf `Up`, der eigentliche Agent scheiterte jedoch ständig:

```text
Radio URL: spinel+hdlc+uart:///dev/ttyACM0?uart-baudrate=1000000
Radio URL: trel://wlan0
No such file or directory
otbr-agent exited with code 5
```

### Auffälligkeit

Die Compose-Datei enthielt:

```text
OTBR_AGENT_OPTS
```

Der laufende Container verwendete trotzdem `/dev/ttyACM0`, `1000000` Baud und `wlan0`.

### Systematische Analyse

Das tatsächliche Startskript im Container wurde gelesen:

```bash
docker exec otbr cat /etc/s6-overlay/s6-rc.d/otbr-agent/run
```

Das Skript wertete aus:

```text
OT_RCP_DEVICE
OT_INFRA_IF
OT_THREAD_IF
OT_LOG_LEVEL
```

`OTBR_AGENT_OPTS` wurde nicht verwendet.

### Root Cause

Das aktuelle OTBR-Image ignorierte `OTBR_AGENT_OPTS` und fiel auf seine Standardwerte zurück.

### Fix

```yaml
environment:
  OT_RCP_DEVICE: "spinel+hdlc+uart:///dev/thread?uart-baudrate=460800&uart-flow-control"
  OT_INFRA_IF: "eno1"
  OT_THREAD_IF: "wpan0"
  OT_LOG_LEVEL: "7"
```

Container nicht nur neu starten, sondern neu erstellen:

```bash
docker compose up -d --force-recreate --no-deps otbr
```

### Verifikation

```text
Radio URL: spinel+hdlc+uart:///dev/thread?uart-baudrate=460800&uart-flow-control
Radio URL: trel://eno1
Infra link selected: eno1
Radio Co-processor version: SL-OPENTHREAD/...
service otbr-agent successfully started
```

---

## Phase 6 – Thread-Netzwerk

Vor dem Hinzufügen der OTBR-Integration:

```bash
docker exec otbr ot-ctl state
```

Ergebnis:

```text
disabled
```

```bash
docker exec otbr ot-ctl dataset active -x
```

Ergebnis:

```text
Error 23: NotFound
```

Die REST-API war jedoch erreichbar:

```bash
curl http://127.0.0.1:8081/node
```

Nach dem Hinzufügen des OpenThread Border Routers in Home Assistant wurde das von Home Assistant verwaltete Thread-Netzwerk aktiviert.

Verifikation:

```text
state: leader
routerCount: 1
networkName: OpenThread-...
```

Das aktive Dataset darf nicht veröffentlicht werden.

---

## Phase 7 – Matter-Server bleibt auf `Created`

### Symptom

```text
container otbr has no healthcheck configured
dependency failed to start
```

### Root Cause

Der Matter-Server verwendete:

```yaml
depends_on:
  otbr:
    condition: service_healthy
```

OTBR besaß keinen Docker-Healthcheck.

### Fix

```yaml
depends_on:
  otbr:
    condition: service_started
```

### Verifikation

```text
Matter Server successfully initialized
```

---

## Phase 8 – Bluetooth für serverseitiges Commissioning

Der Matter-Server lief, hatte aber zunächst keinen explizit gewählten Bluetooth-Adapter.

### Fix

```yaml
command: >-
  --storage-path /data
  --paa-root-cert-dir /data/credentials
  --primary-interface eno1
  --bluetooth-adapter 0
  --port 5580
```

Zusätzlich:

```yaml
volumes:
  - /run/dbus:/run/dbus:ro
```

Prüfung:

```bash
bluetoothctl show
rfkill list bluetooth
docker exec matter-server test -S /run/dbus/system_bus_socket
```

---

## Phase 9 – Mobile Einrichtung unter GrapheneOS

### Umgebung

- Pixel mit GrapheneOS
- Home Assistant Companion App im vertraulichen Profil
- sandboxed Google Play
- Proton VPN mit Always-on-VPN und blockierten Verbindungen ohne VPN

### Erstes Problem

Der Zugriff auf Home Assistant war aus dem vertraulichen Profil blockiert:

```text
ERR_NETWORK_ACCESS_DENIED
```

Der Zugriff funktionierte erst nach dem Deaktivieren von Proton VPN und „Verbindungen ohne VPN blockieren“.

### Zweites Problem

Das Gerät wurde über Google Play Services sofort per Bluetooth erkannt. Die Home-Assistant-Matter-Oberfläche meldete nach dem QR-Code jedoch dauerhaft:

```text
kein WLAN
```

Die erforderlichen Berechtigungen, Thread-Zugangsdaten und Standortfreigaben waren vorhanden.

### Bewertung

Die mobile Commissioning-Kette war in dieser Kombination nicht zuverlässig nutzbar. Die serverseitige Infrastruktur war dagegen vollständig funktionsfähig.

---

## Phase 10 – serverseitiges Commissioning

Der Python Matter Server bietet über seine WebSocket-API:

- `set_thread_dataset`
- `commission_with_code`

Der Matter-Server nutzte Bluetooth des EliteDesk, um den Aqara P2 zu erreichen und das Thread-Dataset zu übertragen.

Das Hilfsskript befindet sich unter:

```text
scripts/matter/commission-thread-device.sh
```

### Ergebnis

- BLE-Verbindung erfolgreich
- Thread-Zugangsdaten übertragen
- Gerät in das aktive Thread-Netz aufgenommen
- Matter-Commissioning abgeschlossen
- Aqara P2 automatisch in Home Assistant sichtbar
- Türkontakt in Home Assistant funktionsfähig

---

## Verifizierter Endzustand

### OTBR

```text
state: leader
routerCount: 1
```

### Matter Server

```text
Matter Server successfully initialized
```

### Home Assistant

- MQTT verbunden
- OTBR-Integration verbunden
- Thread-Netzwerk bevorzugt
- Matter-Integration mit eigenem Matter Server verbunden
- Aqara P2 als Matter-over-Thread-Gerät vorhanden

---

## Verworfen beziehungsweise falsch

Folgende Ansätze sollten nicht wiederholt werden:

- auf einen angeblich eingebetteten Zigbee2MQTT-MQTT-Broker warten
- Firmwareversionen eines Zigbee-Koordinators mit `screen`, `minicom` oder Enter-Zeichen abfragen
- `OTBR_AGENT_OPTS` für das dokumentierte OTBR-Image verwenden
- den Containerstatus `Up` mit einem funktionierenden `otbr-agent` gleichsetzen
- `service_healthy` ohne definierten Healthcheck verwenden
- Thread-Datasets manuell neu erzeugen, wenn Home Assistant das Netzwerk bereits verwaltet
- einen funktionierenden Matter-Code oder ein aktives Dataset in Logs oder GitHub veröffentlichen
- das mobile GrapheneOS-Commissioning als Beweis für einen Fehler der Server-Infrastruktur behandeln

---

## Lessons Learned

1. Der Prozess im Container ist wichtiger als der Containerstatus.
2. Die tatsächlichen Startskripte eines Images sind belastbarer als vermutete Umgebungsvariablen.
3. `docker restart` übernimmt keine Compose-Änderungen.
4. USB-Geräte sollten über `/dev/serial/by-id/` eingebunden werden.
5. Host-Networking umgeht die Host-Firewall nicht.
6. Zigbee2MQTT benötigt einen externen MQTT-Broker.
7. Matter benötigt funktionierendes lokales IPv6 und mDNS, aber kein IPv6-Internet.
8. Das mobile Commissioning ist nur eine mögliche Commissioning-Instanz.
9. Ein Matter-Controller mit Bluetooth kann neue Geräte auch serverseitig provisionieren.
10. Thread-Dataset, Matter-Code und Zigbee-Netzwerkschlüssel sind Geheimnisse.
