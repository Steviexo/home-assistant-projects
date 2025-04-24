# Dokumentation: Anwesenheitserkennung

Dieses Dokument beschreibt die Konfiguration und Logik hinter der Anwesenheitserkennung in meinem Home Assistant Setup. Sie bildet die Grundlage für zahlreiche Automatisierungen, insbesondere im Bereich Lichtsteuerung und Energiemanagement.

---

## 🔍 Tracker und Methoden

### 📱 Companion App
- Installiert auf Fairphone 3 mit **/e/OS**
- Vollversion (nicht Minimalversion) aus alternativer Quelle
- Standortaktualisierung auf "Immer schnell" (1 Min. Intervall)
- Sendet u. a.:
  - `device_tracker.fp3`
  - Standort, Bewegung, Aktivitätsstatus

### 🌐 AVM Fritz!Box Tools
- Überwachung der WLAN-Verbindung
- Entität: `device_tracker.android`
- Ergänzend aktiv für Redundanz, aber nicht Hauptquelle

### 👤 `person.stevie`
- Kombiniert (zeitweise) beide Tracker
- Primäre Referenz für Automatisierungen

---

## 🧠 Stabilitäts-Workaround: Helfer-Flag `input_boolean.stabil_zuhause`

### Ziel
Manche Automatisierungen (z. B. "Its gettin dark") benötigen eine stabile Anwesenheit. Da Tracker mitunter kurzzeitig auf "abwesend" springen, wurde ein **Helfer** eingeführt.

### Konfiguration
- `input_boolean.stabil_zuhause`: wird aktiviert, wenn `person.stevie` für mind. X Minuten kontinuierlich zuhause ist.
- Zwei zugehörige Automatisierungen:
  - **Setzen**: Wenn `person.stevie` seit 10 Minuten zuhause ist → `input_boolean.turn_on`
  - **Zurücksetzen**: Wenn `person.stevie` auf "not_home" wechselt → `input_boolean.turn_off`

Dieser Zustand kann als Bedingung in sensiblen Automatisierungen verwendet werden.

---

## 📋 Offene Punkte & Weiterentwicklung
- Alternative Tracker wie **OwnTracks** oder **GPSLogger** sind vorbereitet, aber noch nicht im Einsatz.
- Wetterbedingte Anpassung der An-/Abwesenheitserkennung geplant (z. B. bei starkem Regen keine Bewegungserkennung als Auslöser).
- Kombination mit Gästeerkennung denkbar.

---

> 📌 Ziel ist eine präzise, aber fehlertolerante Anwesenheitserkennung, die zuverlässig zwischen kurzfristiger Bewegung und tatsächlicher Abwesenheit unterscheidet.
