#!/usr/bin/env bash
set -Eeuo pipefail

OTBR_CONTAINER="${OTBR_CONTAINER:-otbr}"
MATTER_CONTAINER="${MATTER_CONTAINER:-matter-server}"
MATTER_WS_URL="${MATTER_WS_URL:-http://127.0.0.1:5580/ws}"

die() {
  printf 'Fehler: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || die "docker wurde nicht gefunden."

docker inspect "$OTBR_CONTAINER" >/dev/null 2>&1 \
  || die "OTBR-Container '$OTBR_CONTAINER' wurde nicht gefunden."

docker inspect "$MATTER_CONTAINER" >/dev/null 2>&1 \
  || die "Matter-Container '$MATTER_CONTAINER' wurde nicht gefunden."

[[ "$(docker inspect -f '{{.State.Running}}' "$OTBR_CONTAINER")" == "true" ]] \
  || die "OTBR-Container läuft nicht."

[[ "$(docker inspect -f '{{.State.Running}}' "$MATTER_CONTAINER")" == "true" ]] \
  || die "Matter-Container läuft nicht."

THREAD_DATASET="$(
  docker exec "$OTBR_CONTAINER" ot-ctl dataset active -x 2>/dev/null |
    sed -n '1p' |
    tr -d '\r\n'
)"

[[ "$THREAD_DATASET" =~ ^[0-9A-Fa-f]+$ ]] \
  || die "Kein gültiges aktives Thread-Dataset gefunden."

if command -v bluetoothctl >/dev/null 2>&1; then
  bluetoothctl scan off >/dev/null 2>&1 || true
fi

printf '%s\n' \
  "Matter-over-Thread-Commissioning" \
  "--------------------------------" \
  "1. Gerät auf Werkseinstellungen beziehungsweise in den Pairing-Modus setzen." \
  "2. Gerät nahe an den Bluetooth-Adapter des Docker-Hosts legen." \
  "3. Numerischen Matter-Code eingeben; Bindestriche und Leerzeichen sind erlaubt." \
  ""

read -rsp "Matter-Einrichtungscode: " MATTER_CODE_RAW
printf '\n'

MATTER_CODE_RAW="${MATTER_CODE_RAW//$'\r'/}"
MATTER_CODE_RAW="${MATTER_CODE_RAW//$'\n'/}"

if [[ "$MATTER_CODE_RAW" == MT:* ]]; then
  MATTER_CODE="$MATTER_CODE_RAW"
else
  MATTER_CODE="$(printf '%s' "$MATTER_CODE_RAW" | tr -cd '0-9')"
  [[ "$MATTER_CODE" =~ ^[0-9]{11}$ ]] \
    || die "Der manuelle Matter-Code muss 11 Ziffern enthalten."
fi

cleanup() {
  unset THREAD_DATASET MATTER_CODE MATTER_CODE_RAW
}
trap cleanup EXIT

docker exec -i \
  -e THREAD_DATASET="$THREAD_DATASET" \
  -e MATTER_CODE="$MATTER_CODE" \
  -e MATTER_WS_URL="$MATTER_WS_URL" \
  "$MATTER_CONTAINER" python3 - <<'PY'
import asyncio
import json
import os
import sys

from aiohttp import ClientSession, WSMsgType


async def receive_response(ws, message_id: str, timeout: int = 300):
    async with asyncio.timeout(timeout):
        while True:
            message = await ws.receive()

            if message.type == WSMsgType.TEXT:
                data = json.loads(message.data)

                if str(data.get("message_id", "")) != message_id:
                    event = data.get("event")
                    if event:
                        print(f"Ereignis: {event}")
                    continue

                error_code = data.get("error_code")
                if error_code not in (None, 0):
                    details = data.get("details", data)
                    raise RuntimeError(f"Befehl fehlgeschlagen: {details}")

                return data

            if message.type in {
                WSMsgType.CLOSED,
                WSMsgType.CLOSE,
                WSMsgType.ERROR,
            }:
                raise RuntimeError("WebSocket-Verbindung wurde geschlossen.")


async def send_command(ws, message_id: str, command: str, args: dict):
    print(f"Sende {command} ...")
    await ws.send_json(
        {
            "message_id": message_id,
            "command": command,
            "args": args,
        }
    )
    return await receive_response(ws, message_id)


async def main():
    dataset = os.environ.get("THREAD_DATASET", "").strip()
    setup_code = os.environ.get("MATTER_CODE", "").strip()
    ws_url = os.environ.get(
        "MATTER_WS_URL",
        "http://127.0.0.1:5580/ws",
    ).strip()

    if not dataset:
        sys.exit("Kein Thread-Dataset vorhanden.")

    if not setup_code:
        sys.exit("Kein Matter-Einrichtungscode vorhanden.")

    async with ClientSession() as session:
        async with session.ws_connect(ws_url, max_msg_size=0) as ws:
            initial = await ws.receive()
            if initial.type != WSMsgType.TEXT:
                raise RuntimeError(
                    "Matter-Server sendete keine gültige Initialnachricht."
                )

            print("Matter-Server verbunden.")

            await send_command(
                ws,
                "thread-dataset",
                "set_thread_dataset",
                {"dataset": dataset},
            )

            print(
                "Thread-Dataset gesetzt. "
                "Commissioning wird über Bluetooth gestartet ..."
            )

            result = await send_command(
                ws,
                "commission",
                "commission_with_code",
                {"code": setup_code},
            )

            print("Commissioning erfolgreich abgeschlossen.")
            result_data = result.get("result")
            if result_data is not None:
                print(json.dumps(result_data, ensure_ascii=False, indent=2))


asyncio.run(main())
PY
