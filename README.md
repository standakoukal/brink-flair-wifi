# brink-flair-wifi

WiFi interface for the **Brink Flair 325** heat-recovery ventilation unit, built on **ESPHome** and integrated into **Home Assistant**. The bridge talks to the unit over **Modbus RTU** (RS485).

## Hardware

- [Seeed Studio XIAO ESP32C3](https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/) — WiFi MCU
- [Seeed Studio XIAO RS485 Expansion Board](https://wiki.seeedstudio.com/XIAO-RS485-Expansion-Board/) — RS485 transceiver, 120 Ω terminator switch, screw terminals
- DC-DC step-down 5–30 V → 5 V / 3 A (non-isolated)
- Powered from the unit's 24 V output

See [docs/wiring.md](docs/wiring.md) for the full wiring diagram and pin map, and [docs/registers.md](docs/registers.md) for the Modbus register reference. A 3D-printable enclosure source lives in [mechanical/](mechanical/).

## Project status

🚧 Early development — wiring designed, firmware drafted, awaiting first hardware bring-up.

- [x] Source review
- [x] Wiring diagram
- [x] ESPHome configuration with all known registers from the community thread
- [ ] Bring-up: flash over USB and confirm Modbus reads
- [ ] Validate which registers actually work on a unit without the UWA2-B card
- [ ] Confirm writes (start with `Ventilation step` after setting `Modbus control mode = Step`)
- [ ] OTA update workflow

## ESPHome configuration

The ESPHome YAML lives at [esphome/brink-flair-325.yaml](esphome/brink-flair-325.yaml). The configuration uses **dashboard secrets**, so the following keys must exist in the dashboard's shared `secrets.yaml`:

| Key | Purpose |
|---|---|
| `wifi_ssid` | WiFi network SSID |
| `wifi_password` | WiFi password |
| `ap_password` | Fallback hotspot password (`brink-flair-325 fallback`) |
| `api_key` | Home Assistant native-API encryption key (32-byte base64) |
| `ota_password` | OTA update password |

Generate the `api_key` either in the dashboard UI (it offers a button) or with `openssl rand -base64 32`.

### First flash

1. Connect the XIAO to the PC over USB-C with the unit **disconnected**.
2. In the ESPHome dashboard, click *Install → Plug into this computer* and pick the XIAO's COM port.
3. Once Online, disconnect USB and power the board from the unit's 24 V via the step-down. Subsequent updates can go OTA.

## References

- HA community thread: <https://community.home-assistant.io/t/brink-flair-325-heat-recovery-unit-esphome-modbus-integration-5/423182>
- ESPHome Modbus Controller: <https://esphome.io/components/modbus_controller.html>

## License

MIT (to be added)
