# brink-flair-wifi

WiFi bridge for the **Brink Flair 325** heat-recovery ventilation unit, built on **ESPHome** and integrated into **Home Assistant** over the unit's Modbus RTU interface (RS485). Tested and working on a Flair 325 with Modbus enabled in the menu but **without** the UWA2-B expansion card.

## Hardware

- [Seeed Studio XIAO ESP32C3](https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/) — WiFi MCU
- [Seeed Studio XIAO RS485 Expansion Board](https://wiki.seeedstudio.com/XIAO-RS485-Expansion-Board/) — TP8485E transceiver, 120 Ω terminator switch, screw terminals
- DC-DC step-down 5–30 V → 5 V / 3 A (non-isolated)
- Powered from the unit's 24 V output

See [docs/wiring.md](docs/wiring.md) for the wiring diagram and the corrected ESP32-C3 pin map, and [docs/registers.md](docs/registers.md) for the validated Modbus register reference with full enum decodings.

## Project status

✅ **Working — full bidirectional integration**, including direct fan-speed control via the Modbus **Flow** mode (`Modbus control mode = Flow`, `Flow setpoint` register 8002). This is true on a Flair 325 *without* the UWA2-B expansion card — initial assumption that ventilation control needs UWA2-B turned out to be wrong.

⚠️ One caveat: the Modbus **Step** mode (`Modbus control mode = Step`, register 8001) does **not** work without UWA2-B — writes are acknowledged but the unit silently flips Unit mode to `Manual` and the fans don't change. **Use Flow mode** for HA-driven ventilation control.

| Group | Count | What you get |
|---|---:|---|
| Sensors (read-only) | 8 | supply / exhaust / outdoor temperature, supply / exhaust humidity, both airflows, filter status |
| Text sensors | 3 | bypass state, unit mode, filter status (Clean/Dirty) |
| Number controls | 8 | ventilation step¹, **flow setpoint (works!)**, flow levels 0–3, in/out flow imbalance² |
| Select controls | 2 | Modbus control mode, bypass mode |
| Switch controls | 1 | bypass boost |
| Diagnostics | 4 | online status, WiFi RSSI, uptime, IP / SSID |

¹ Ventilation step (8001) is exposed as a writable slider but only takes effect with UWA2-B installed.
² Imbalance registers (6035/6036) — community thread and Brink official docs disagree on their meaning. Don't move the sliders blindly. See [docs/registers.md](docs/registers.md).

## Key gotchas (so you don't repeat my mistakes)

1. **Pin map** — the Seeed wiki labels D4 as "RX" and D5 as "TX", but those names refer to the TP8485E chip-side pins. From the **ESP** side it is the opposite: `D4 = GPIO6 → ESP TX`, `D5 = GPIO7 → ESP RX`, `D2 = GPIO4 → DE/RE`. The HA community thread cites `GPIO 16/17`, which is for the classic ESP32, not ESP32-C3.
2. **Logger UART** — on ESP32-C3 use `hardware_uart: USB_SERIAL_JTAG`, not `USB_CDC`. The latter triggers safe-mode boot loops in ESPHome 2026.4.5.
3. **Function codes split** — control registers `6xxx` / `8xxx` work over **FC 0x03** (`register_type: holding`); status registers `4xxx` work over **FC 0x04** (`register_type: read`). Without the UWA2-B card the holding-table side of the 4xxx range is unmapped — the sensors must use the input-register table.
4. **Enum mappings** — the HA thread's bypass and unit-mode enums are incomplete. Bypass is 5-state (`Initialize / Opening / Closing / Open / Closed`), unit mode is 15-state (full table in [docs/registers.md](docs/registers.md)).
5. **Power cycle after OTA** — occasionally the Modbus stack is left in a flaky state (`Clearing buffer of 1 bytes - timeout after partial response`). A power cycle clears it.

## ESPHome configuration

The ESPHome YAML lives at [esphome/brink-flair-325.yaml](esphome/brink-flair-325.yaml). It pulls credentials from the dashboard's shared `secrets.yaml`:

| Key | Purpose |
|---|---|
| `wifi_ssid` | WiFi network SSID |
| `wifi_password` | WiFi password |
| `ap_password` | Fallback hotspot password |
| `api_key` | Home Assistant native-API encryption key (32-byte base64) |
| `ota_password` | OTA update password |

### Modbus settings on the unit

In the unit's menu set **Communication → Bus type → modbus → address `1` → `19k2` → parity `NONE`**.

### First flash

1. Connect the XIAO to the PC over USB-C with the unit **disconnected**.
2. In the ESPHome dashboard, click **Install → Plug into this computer** and pick the XIAO's COM port.
3. After the device is **Online** in HA, disconnect USB and power the board from the unit's 24 V via the step-down. Further updates can go OTA.

## References

- [HA community thread — Brink Flair 325 ESPHome integration](https://community.home-assistant.io/t/brink-flair-325-heat-recovery-unit-esphome-modbus-integration-5/423182)
- [Brink Modbus UWA2-B / UWA2-E installation regulations PDF](https://www.brinkclimatesystems.nl/documenten/modbus-uwa2-b-uwa2-e-installation-regulations-614882.pdf)
- [TapHome — Brink Flair compatibility (full enum mapping)](https://taphome.com/en/compatibility/brink-flair/)
- [icecoldfire/HomeAssistant-Brink-Flair-ModBus](https://github.com/icecoldfire/HomeAssistant-Brink-Flair-ModBus)
- [ESPHome Modbus Controller](https://esphome.io/components/modbus_controller.html)
- [Seeed XIAO RS485 Expansion Board — wiki and discussion (RX/TX clarification by Elu43)](https://wiki.seeedstudio.com/XIAO-RS485-Expansion-Board/)

## License

MIT (to be added)
