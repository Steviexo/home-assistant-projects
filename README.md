# Home Assistant Projects

Dieses Repository dokumentiert praxisnah aufgebaute Home-Assistant-Projekte, Automatisierungen, Integrationen und reale Fehleranalysen.

Der Schwerpunkt liegt nicht nur auf funktionierenden Konfigurationen, sondern auch auf nachvollziehbaren Architekturentscheidungen, Prüfpfaden, Root-Cause-Analysen und Lessons Learned.

> **Status:** Das Repository wird schrittweise auf eine einheitliche Dokumentationsstruktur umgestellt. Bestehende Ordner bleiben zunächst erhalten und werden nach Bedarf migriert.

---

## Repository-Struktur

```text
home-assistant-projects/
├── automations/                 # Home-Assistant-Automatisierungen
├── blueprints/                  # Eigene oder angepasste Blueprints
├── helpers/                     # Helfer und YAML-Bausteine
├── docs/
│   ├── services/                # Soll-Zustand, Architektur und Betrieb
│   ├── incidents/               # Konkrete Vorfälle und Root-Cause-Analysen
│   └── troubleshooting/         # Wiederverwendbare Diagnosepfade
├── examples/                    # Bereinigte Konfigurationsbeispiele
├── scripts/                     # Hilfsskripte für Betrieb und Provisionierung
├── reverse-proxy-setup/         # Bestehendes Projekt, spätere Migration möglich
├── skyconnect-issue-fix/        # Bestehende Alt-Dokumentation
└── configuration.yaml           # Beispiel beziehungsweise Auszug
```

---

## Dokumentierte Projekte

### Zigbee, Thread und Matter mit Home Assistant Container

Migration auf zwei getrennte Funkkoordinatoren:

- Sonoff Zigbee 3.0 USB Dongle Plus für Zigbee
- Home Assistant SkyConnect / Connect ZBT-1 mit OpenThread-RCP-Firmware für Thread
- Zigbee2MQTT und Mosquitto für Zigbee
- OpenThread Border Router und Python Matter Server für Matter-over-Thread
- serverseitiges Matter-Commissioning über Bluetooth des Docker-Hosts

Relevante Dokumentation:

- [`docs/services/zigbee-thread-matter-stack.md`](docs/services/zigbee-thread-matter-stack.md)
- [`docs/incidents/migration-zigbee-thread-matter.md`](docs/incidents/migration-zigbee-thread-matter.md)
- [`docs/troubleshooting/zigbee-thread-matter.md`](docs/troubleshooting/zigbee-thread-matter.md)
- [`scripts/matter/commission-thread-device.sh`](scripts/matter/commission-thread-device.sh)

---

## Dokumentationsprinzipien

- Soll-Zustand, Incident und Troubleshooting werden getrennt dokumentiert.
- Befehle und Prüfungen müssen reproduzierbar sein.
- Gerätepfade werden nach Möglichkeit über `/dev/serial/by-id/` eingebunden.
- Geheimnisse, Thread-Datasets, Matter-Codes, Kennwörter und Tokens gehören nicht ins Repository.
- Funktionierende Endzustände werden klar von verworfenen Ansätzen getrennt.
- Änderungen an Docker-Compose werden vor dem Start mit `docker compose config` validiert.

---

## Sicherheit

Vor einem öffentlichen Commit prüfen:

```bash
git grep -nE \
  'password|token|network_key|dataset active|MT:|[0-9]{11}|usb-.*_[0-9a-f]{16,}'
```

Nicht veröffentlichen:

- Matter-Setup-Codes und Matter-QR-Payloads
- aktive Thread-Datasets
- Zigbee-Netzwerkschlüssel
- MQTT-Kennwörter
- Home-Assistant-Tokens
- private Zertifikate
- persönliche USB-Seriennummern, wenn diese nicht bewusst veröffentlicht werden sollen

---

## Referenzen

- [Home Assistant – Thread](https://www.home-assistant.io/integrations/thread/)
- [Home Assistant – Matter](https://www.home-assistant.io/integrations/matter/)
- [OpenThread Border Router – Docker](https://openthread.io/guides/border-router/build-docker)
- [Zigbee2MQTT – Dokumentation](https://www.zigbee2mqtt.io/)
- [Python Matter Server – WebSocket API](https://github.com/home-assistant-libs/python-matter-server/blob/main/docs/websockets_api.md)
