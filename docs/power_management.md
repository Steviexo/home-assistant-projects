# Dokumentation: Power Management

Dieses Dokument beschreibt meine Maßnahmen zur automatisierten Steuerung von Stromverbrauchern, insbesondere über smarte Steckdosenleisten. Ziel ist es, Energie effizient zu nutzen, unnötigen Verbrauch zu vermeiden und zentrale Verbraucher zeit- oder zustandsabhängig zu steuern.

---

## 🔌 Anwendungsfall: Mehrfachsteckdosenleiste

### Beschreibung
- Eingesetzt im Wohnzimmer für TV, Mediengeräte und Lichtquellen
- Smart gesteuert via Zigbee-fähige Steckdosen

### Automatisierung: `power_strip_control`
- **Ziel**: Automatisiertes Ein- und Ausschalten der Steckdosenleiste abhängig von der Uhrzeit

### Technische Umsetzung
- YAML-basierte `choose:`-Struktur mit zwei Triggern:
  - `22:00`: Steckdosenleiste einschalten
  - `02:00`: Steckdosenleiste ausschalten
- Einzige Automatisierung statt zwei separater

```yaml
trigger:
  - platform: time
    at: "22:00:00"
  - platform: time
    at: "02:00:00"
action:
  - choose:
      - conditions:
          - condition: template
            value_template: "{{ now().strftime('%H:%M') == '22:00' }}"
        sequence:
          - service: switch.turn_on
            target:
              entity_id: group.power_strip
      - conditions:
          - condition: template
            value_template: "{{ now().strftime('%H:%M') == '02:00' }}"
        sequence:
          - service: switch.turn_off
            target:
              entity_id: group.power_strip
```

---

## 💡 Weitere Überlegungen
- Ergänzung um Anwesenheitsbedingungen möglich: Nur einschalten, wenn `person.stevie` zuhause ist
- Erweiterung um Energieverbrauchs-Sensorik geplant (z. B. `sensor.steckdosenleiste_power`)
- Geplant: Integration in Energiespar-Modus bei längerer Abwesenheit (z. B. Urlaub)

---

> ♻️ Ziel ist eine smarte und nachhaltige Nutzung von Stromverbrauchern – mit möglichst geringem manuellem Aufwand.
