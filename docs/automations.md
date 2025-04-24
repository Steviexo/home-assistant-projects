# Dokumentation: Automatisierungen

In diesem Abschnitt werden die wichtigsten Automatisierungen meines Home Assistant Setups beschrieben. Ziel ist es, die jeweiligen Trigger, Bedingungen und Aktionen nachvollziehbar darzustellen sowie ihre Funktion im Alltag zu erklären.

---

## 💡 Beleuchtungsautomatisierungen (`automations/lighting/`)

### 📘 Its gettin dark
- **Zweck**: Schaltet das Wohnzimmerlicht ein, wenn es abends dunkel wird und ich zuhause bin.
- **Trigger**:
  - Täglich um 16:30 Uhr **oder**
  - Helligkeitssensor meldet < 5 lx über 10 Minuten hinweg
- **Bedingungen**:
  - Ich bin zuhause (`person.stevie`)
  - Uhrzeit zwischen 16:00 und 22:00 Uhr
- **Aktion**:
  - Wohnzimmerlicht einschalten (`area_id: wohnzimmer`)

### 📘 Cloudy days need light
- **Zweck**: Reagiert auf bewölkte Tage mit niedriger Raumhelligkeit und schaltet Licht ein, wenn ich zuhause bin.
- **Blueprint**: basiert auf YAMA (angepasst)
- **Trigger**:
  - 09:00 Uhr **oder**
  - Helligkeit unter 10 lx für 10 Minuten
- **Bedingungen**:
  - Ich bin zuhause
  - Zeitfenster: 09:00–17:00 Uhr
  - Wetterstatus = "cloudy"
- **Aktion**:
  - Wohnzimmerlicht über YAMA-Blueprint steuern

---

## 🧍 Anwesenheitsautomatisierungen (`automations/presence/`)

### 📘 I'm home
- **Zweck**: Schaltet Licht beim Heimkommen ein.
- **Trigger**: Standortwechsel `person.stevie` betritt Zone "home"
- **Bedingungen**:
  - Licht ist noch aus
  - Uhrzeit: zwischen Sonnenuntergang oder bewölktem Wetter (geplant)
- **Aktion**:
  - Wohnzimmerlicht einschalten

### 📘 Leave home
- **Zweck**: Schaltet Licht beim Verlassen der Wohnung aus.
- **Trigger**: `person.stevie` verlässt Zone "home"
- **Bedingung**: Licht ist an
- **Aktion**: Licht ausschalten

---

## 🔌 Stromsparautomatisierung (`automations/power_management/`)

### 📘 Power strip control
- **Zweck**: Schaltet Steckdosenleiste automatisch ein/aus
- **Trigger**:
  - 22:00 Uhr (ein)
  - 02:00 Uhr (aus)
- **Aktion**: `switch.turn_on` oder `switch.turn_off` mit `choose:`-Logik basierend auf Uhrzeit

---

> 🔄 Diese Automatisierungen werden regelmäßig überprüft und bei Bedarf optimiert, um sich an den Alltag und neue Anforderungen anzupassen.
