# brink-flair-wifi

WiFi interface for the **Brink Flair 325** heat-recovery ventilation unit, built on **ESPHome** and integrated into **Home Assistant**. The bridge talks to the unit over **Modbus RTU** (RS485).

## Hardware

- [Seeed Studio XIAO ESP32C3](https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/) — WiFi MCU
- [Seeed Studio XIAO RS485 Expansion Board](https://wiki.seeedstudio.com/XIAO-RS485-Expansion-Board/) — RS485 transceiver, 120 Ω terminator switch, screw terminals
- DC-DC step-down 5–30 V → 5 V / 3 A (non-isolated)
- Powered from the unit's 24 V output

See [docs/wiring.md](docs/wiring.md) for the full wiring diagram and pin map.

## Project status

🚧 Early development — wiring designed, firmware in progress.

- [x] Source review
- [x] Wiring diagram
- [ ] ESPHome skeleton (UART + Modbus controller)
- [ ] Read-only sensors (temperatures, airflows, bypass state)
- [ ] Control entities (ventilation step, bypass mode)
- [ ] Validate Modbus registers on the actual unit (Modbus enabled without UWA2-B card)
- [ ] OTA update workflow

## References

- HA community thread: <https://community.home-assistant.io/t/brink-flair-325-heat-recovery-unit-esphome-modbus-integration-5/423182>
- ESPHome Modbus Controller: <https://esphome.io/components/modbus_controller.html>

## License

MIT (to be added)
