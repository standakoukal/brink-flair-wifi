# Modbus register reference

All registers are reached via Modbus function code **03 (Read Holding Registers)** and **06 (Write Single Register)**. Slave address `0x01`. Source: [HA community thread](https://community.home-assistant.io/t/brink-flair-325-heat-recovery-unit-esphome-modbus-integration-5/423182).

> **Note on UWA2-B:** the full register map is officially documented only in the UWA2-B expansion card manual. On a unit with Modbus enabled in the menu but **without** the UWA2-B card (this project's setup), some registers may be unavailable or read-only. Validate one register at a time before relying on it.

## Read-only sensors (4xxx range)

| Address | Name (this project) | Type | Scale | Unit | Notes |
|--------:|---|---|---:|---|---|
| 4020 | Unit mode | S_WORD enum | – | – | 0 Standby / 1 Normal / 2 Bootloader / 3 Error |
| 4032 | Supply airflow (actual) | S_WORD | 1 | m³/h | |
| 4036 | Supply temperature (to house) | S_WORD | 0.1 | °C | Air leaving the unit toward the rooms |
| 4037 | Supply humidity | S_WORD | 1 | % | |
| 4042 | Exhaust airflow (actual) | S_WORD | 1 | m³/h | |
| 4046 | Exhaust temperature (to outside) | S_WORD | 0.1 | °C | Air leaving the unit toward outside |
| 4047 | Exhaust humidity | S_WORD | 1 | % | |
| 4050 | Bypass state | S_WORD enum | – | – | 0 Init / 1 Open / 2 Closed |
| 4081 | Outdoor temperature (intake) | S_WORD | 0.1 | °C | Outside air entering the unit |
| 4100 | Filter status | S_WORD enum | – | – | Bitfield; non-zero = service due |

The thread notes there is no extract-air sensor between house and unit on this model — heat-recovery efficiency must be estimated from outdoor↔exhaust temperature delta.

## Writable controls (6xxx and 8xxx ranges)

| Address | Name | Type | Range | Notes |
|--------:|---|---|---|---|
| 6001 | Flow level 1 | S_WORD | 50–325 m³/h | Each level must be ≥ the previous one. |
| 6002 | Flow level 2 | S_WORD | 50–325 m³/h | Each level must be ≥ the previous one. |
| 6003 | Flow level 3 | S_WORD | 50–325 m³/h | Each level must be ≥ the previous one. |
| 6035 | Inflow imbalance | S_WORD | -15…+15 % | |
| 6036 | Outflow imbalance | S_WORD | -15…+15 % | |
| 6100 | Bypass mode | U_WORD enum | 0 Auto / 1 Closed / 2 Open | When forced, may suppress flow commands. |
| 6104 | Bypass boost | bit | 0/1 | Switch in HA. |
| 8000 | Modbus control mode | U_WORD enum | 0 LCD / 1 Step / 2 Flow | **Must be 1 or 2 for steps/flow writes to take effect.** |
| 8001 | Ventilation step | S_WORD | 0–3 | Active when 8000 = Step. |
| 8002 | Flow setpoint | S_WORD | 0–280 m³/h | Active when 8000 = Flow. |

## Validation log

Track which registers actually work on this specific unit (without UWA2-B) here as the project progresses:

| Date | Register | Read OK | Write OK | Notes |
|---|---|---|---|---|
| _TBD_ | 4036 | ? | – | first power-on test |
