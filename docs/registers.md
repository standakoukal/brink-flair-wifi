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
| 8001 | Ventilation step | S_WORD | **1–3** | Writes accepted **only when 8000 = Step**, otherwise exception 3 (ILLEGAL_DATA_VALUE). The HA thread's "0–3" range is wrong for the Flair 325. To stop ventilation, switch 8000 to LCD or set 8002 to 0 with 8000 = Flow. |
| 8002 | Flow setpoint | S_WORD | 0–280 m³/h | Writes accepted **only when 8000 = Flow**, otherwise exception 3 (ILLEGAL_DATA_VALUE). |

## Validation log

Track which registers actually work on this specific unit (Brink Flair 325 with Modbus enabled in the menu, **without** the UWA2-B card).

| Date | Register | FC | Read OK | Write OK | Notes |
|---|---|---|---|---|---|
| 2026-05-08 | 6001 Flow level 1 | 0x03 | ✓ (100 m³/h) | _untested_ | |
| 2026-05-08 | 6002 Flow level 2 | 0x03 | ✓ (150 m³/h) | _untested_ | |
| 2026-05-08 | 6003 Flow level 3 | 0x03 | ✓ (250 m³/h) | _untested_ | |
| 2026-05-08 | 6035 Inflow imbalance | 0x03 | ✓ (0 %) | _untested_ | |
| 2026-05-08 | 6036 Outflow imbalance | 0x03 | ✓ (0 %) | _untested_ | |
| 2026-05-08 | 6100 Bypass mode | 0x03 | ✓ (Auto) | _untested_ | |
| 2026-05-08 | 8000 Modbus control mode | 0x03 | ✓ (Step) | _untested_ | |
| 2026-05-08 | 8001 Ventilation step | 0x03 | ✓ (0) | _untested_ | |
| 2026-05-08 | 8002 Flow setpoint | 0x03 | ✓ (0) | _untested_ | |
| 2026-05-08 | 4020 Unit mode | 0x03 | ✗ (exception 2 ILLEGAL_DATA_ADDRESS) | – | also FC 0x04 returns a value but it is not in the {0,1,2,3} mapping from the HA thread — needs decoding |
| 2026-05-08 | 4020 Unit mode | 0x04 | ✓ (raw value mapping unknown) | – | enum mapping for Brink Flair 325 differs from the thread |
| 2026-05-08 | 4032 Supply airflow | 0x04 | ✓ (0 m³/h, idle) | – | |
| 2026-05-08 | 4036 Supply temp | 0x04 | ✓ (25.5 °C) | – | |
| 2026-05-08 | 4037 Supply humidity | 0x04 | ✓ (41 %) | – | |
| 2026-05-08 | 4042 Exhaust airflow | 0x04 | ✓ (0 m³/h, idle) | – | |
| 2026-05-08 | 4046 Exhaust temp | 0x04 | ✓ (22.9 °C) | – | |
| 2026-05-08 | 4047 Exhaust humidity | 0x04 | ✓ (37 %) | – | |
| 2026-05-08 | 4050 Bypass state | 0x04 | ✓ (raw value mapping unknown) | – | enum mapping needs decoding |
| 2026-05-08 | 4081 Outdoor temp | 0x04 | ✓ (20.7 °C) | – | |
| 2026-05-08 | 4100 Filter status | 0x04 | ✓ (0, no service due) | – | |

**Pattern confirmed:**
- Control registers (6xxx, 8xxx) → FC 0x03 (Read Holding) ✓
- Status registers (4xxx) → FC 0x04 (Read Input Register) ✓ on this unit even without the UWA2-B card

The HA community thread implicitly assumed FC 0x03 for everything (which works only with the UWA2-B firmware). Without the card the same addresses are accessible, just through the input-register table.

## Enum decoding

The HA community thread's 3-state bypass mapping and 4-state unit-mode mapping are incomplete for the Flair 325. The official UWA2-B Modbus docs (mirrored in the TapHome integration) have the full enums.

### 4020 Unit mode

| Value | Meaning |
|---:|---|
| 0 | Standby |
| 1 | Bootloader |
| 2 | Non-blocking error |
| 3 | Blocking error |
| 4 | Manual |
| 5 | Holiday |
| 6 | Night ventilation |
| 7 | Party |
| 8 | Bypass boost |
| 9 | Normal boost |
| 10 | Auto CO2 |
| 11 | Auto eBus |
| 12 | Auto Modbus |
| 13 | Auto Portal |
| 14 | Auto Local |

Observed on this unit:
- `12 = Auto Modbus` ✓ when ESP drives 8001/8002 (8000 = Step or Flow)
- `4 = Manual` ✓ when 8000 = LCD and the unit is being driven from its own menu

### 4050 Bypass state

| Value | Meaning |
|---:|---|
| 0 | Initialize |
| 1 | Opening |
| 2 | Closing |
| 3 | Open |
| 4 | Closed |

Observed on this unit:
- `3 = Open` ✓ — confirmed against the unit's LCD readout
- `4 = Closed` ✓ — observed once the bypass closed during normal operation
