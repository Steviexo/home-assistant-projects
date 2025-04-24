# Home Assistant Projects

Dieses Repository enthält verschiedene Projekte und Lösungen im Zusammenhang mit **Home Assistant**, die ich auf meiner **Synology NAS** implementiert habe. Hier findest du Dokumentationen, Anleitungen und Konfigurationsbeispiele zu spezifischen Home Assistant-Themen, die ich in der Praxis gelöst habe.

## Ziel dieses Repositories
Dieses Repository dient der strukturierten Sammlung und Dokumentation meiner Smart-Home-Projekte mit Home Assistant. Ich möchte damit Automatisierungen, Helfer, Szenarien und Integrationen nachvollziehbar und modular abbilden. 

> Hinweis: Mein System befindet sich im laufenden Ausbau, die Inhalte spiegeln meinen aktuellen Stand wider und können sich jederzeit weiterentwickeln.

## 📁 Struktur

```
home-assistant-projects/
├── automations/
│   ├── lighting/                  # Lichtbezogene Automatisierungen
│   ├── presence/                  # Anwesenheitserkennung und -aktionen
│   └── power_management/          # Steuerung von Steckdosen und Energieverbrauch
├── blueprints/
│   └── yama/                      # Angepasste Version des YAMA-Blueprints
├── helpers/
│   └── input_booleans.yaml       # Alle input_boolean-Helfer
├── docs/                         # Projekt- und Themen-Dokumentation
│   ├── automations.md
│   ├── presence_detection.md
│   └── power_management.md
├── reverse-proxy-setup/          # Reverse Proxy für externen Zugriff
├── skyconnect-issue-fix/         # Lösung für SkyConnect-Probleme
├── README.md                     # Diese Datei
└── configuration.yaml            # Hauptkonfigurationsdatei (Auszug oder Beispiel)
```

## 📖 Inhalte

### Automatisierungen (`automations/`)
- **lighting/**: Automatisierungen, die auf Lichtverhältnisse oder Tageszeiten reagieren, z. B. *its gettin dark*, *cloudy days need light*
- **presence/**: An-/Abwesenheitsabhängige Automatisierungen, z. B. *im home*, *leave home*
- **power_management/**: Automatisierungen zur zeit- oder zustandsabhängigen Steuerung von Stromverbrauch, z. B. *power strip control*

### Blueprints (`blueprints/`)
- Enthält modifizierte oder angepasste Versionen von Blueprint-Automatisierungen (z. B. YAMA).

### Helfer (`helpers/`)
- YAML-Datei mit allen verwendeten `input_boolean`-Entitäten, z. B. `stabil_zuhause`

### Dokumentation (`docs/`)
- Markdown-Dateien zur Erklärung und Strukturierung der Automatisierungen, Tracker und Hilfsmittel.

### Weitere Projekte

#### [1. Home Assistant Reverse Proxy Setup](reverse-proxy-setup/README.md)
Einrichtung eines **Reverse Proxy** auf der **Synology NAS**, um **Home Assistant** sicher über HTTPS erreichbar zu machen.
- DSM-Konfiguration
- Let's Encrypt Wildcard-Zertifikat
- Konfiguration der `configuration.yaml`

#### [2. SkyConnect Issue Fix](skyconnect-issue-fix/README.md)
Lösung eines Problems mit dem **SkyConnect-Stick** in Home Assistant.
- Fehlerbeschreibung
- Konkrete Lösungsschritte

## ✅ Ziel
Das Ziel dieses Repositories ist es, meine Automatisierungen transparent, modular und nachvollziehbar zu dokumentieren. Gleichzeitig dient es als Grundlage zur Wiederverwendung und Weiterentwicklung meines Home Assistant Setups.

## 🔗 Nützliche Ressourcen
- [Home Assistant Offizielle Dokumentation](https://www.home-assistant.io/docs/)
- [Synology Reverse Proxy Dokumentation](https://kb.synology.com/en-global/DSM/tutorial/How_to_set_up_Reverse_Proxy_on_Synology_NAS)
- [Let's Encrypt Dokumentation](https://letsencrypt.org/docs/)

---

> ✨ Dieses Projekt ist work-in-progress und wird laufend erweitert und verbessert. Feedback ist willkommen!
