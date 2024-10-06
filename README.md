# SkyConnect Stick nicht erkannt in Home Assistant VM (Synology NAS)

## Problem:
Der **Nabu Casa SkyConnect** Stick wurde in einer **Home Assistant**-Installation auf einem **Synology NAS** in einer VM nicht erkannt. Die Home Assistant-Oberfläche zeigte eine Fehlermeldung in der Zigbee-Integration (ZHA), die darauf hinwies, dass der serielle Port nicht gefunden werden konnte.

### Fehlermeldung:
[Errno 2] could not open port /dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1_0_... No such file or directory

## Umgebung:
- Home Assistant OS 13.1
- Synology NAS mit Virtual Machine Manager (VM)
- Nabu Casa SkyConnect Stick (Silicon Labs CP210x USB to UART Bridge)

## Schritte zur Lösung:

### 1. Physische Überprüfung und USB Passthrough:
   - Der SkyConnect-Stick wurde im NAS unter `lsusb` korrekt erkannt, jedoch nicht in der VM durchgereicht.
   - **Lösung:** In den **VM-Einstellungen** (Synology Virtual Machine Manager) den **USB-Passthrough** für den SkyConnect-Stick (Silicon Labs CP210x) aktivieren. Entfernen und erneutes Hinzufügen des Geräts zur VM half, das Problem zu lösen.

### 2. Überprüfung in der VM:
   - Nach Aktivierung des Passthroughs in der VM war der SkyConnect-Stick unter `/dev/serial/by-id/` sichtbar:
   ```bash
   ls /dev/serial/by-id/
Der Stick wurde als 'usb-Silicon_Labs_CP210x_USB_to_UART_Bridge_Controller_...' erkannt.

### 3. Konfiguration in Home Assistant:
In der Zigbee Home Automation (ZHA)-Integration den seriellen Port korrekt eingestellt:
/dev/serial/by-id/usb-Silicon_Labs_CP210x_USB_to_UART_Bridge_Controller_...

### 4. Neustart und Überprüfung:
Nach dem Neustart von Home Assistant und ZHA war keine Fehlermeldung mehr sichtbar, und die Zigbee-Geräte funktionierten wie erwartet.

### Ergebnis:
Das Problem wurde erfolgreich gelöst, indem der USB-Passthrough korrekt eingerichtet wurde. Der Nabu Casa SkyConnect Stick wird jetzt ordnungsgemäß in Home Assistant erkannt, und die Zigbee-Integration funktioniert fehlerfrei.
