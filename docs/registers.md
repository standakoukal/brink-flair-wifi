# Modbus register reference

Cross-checked against the [official Brink UWA2-B/UWA2-E installation regulations PDF](https://www.brinkclimatesystems.nl/documenten/modbus-uwa2-b-uwa2-e-installation-regulations-614882.pdf) and the [HA community thread](https://community.home-assistant.io/t/brink-flair-325-heat-recovery-unit-esphome-modbus-integration-5/423182). Slave address `0x01`, 19200 8N1.

The Brink Modbus map has three sections:

| Range | Section | Function code | Purpose |
|---|---|---|---|
| 4000–4544 | Input registers | **FC 0x04** (Read Input) | Read-only actual values, sensors, status |
| 6000–7992 | Holding registers | **FC 0x03** (Read) / **0x06** (Write Single) | Setting parameters, read/write |
| 8000–8011 | Remote control | **FC 0x03/0x06** | Commands sent to the unit |

> **Important warning from the official docs (page 5):**
> *"If the Brink HRA has been disconnected from the mains, Modbus address 8000–8011 and the desired air flows must be set again."*
>
> Practical impact: every power cycle of the recovery unit clears the Modbus control mode and ventilation setpoint. Either set them again from HA after each power-on, or add an `on_boot` script in the YAML that re-issues the writes.

## Input registers (4xxx) — read-only

| Address | Name | Type | Scale | Unit | Notes |
|--------:|---|---|---:|---|---|
| 4020 | Unit mode (HRA active function) | S_WORD enum | – | – | 15-state enum (full table below). |
| 4032 | Supply airflow (current) | U_WORD | 1 | m³/h | Measured/calculated value for the supply fan. |
| 4036 | Supply temperature (to house) | S_WORD | 0.1 | °C | Air leaving the unit toward the rooms. |
| 4037 | Supply humidity | U_WORD | 0.1¹ | % | Per docs scale is 0.1 (0–1000 ⇒ 0.0–100.0 %). On this Flair 325 the register reads in plain percent (0–100), so we apply no multiplier. Verify on your unit. |
| 4042 | Exhaust airflow (current) | U_WORD | 1 | m³/h | Measured/calculated value for the exhaust fan. |
| 4046 | Exhaust temperature (to outside) | S_WORD | 0.1 | °C | Air leaving the unit toward outside. |
| 4047 | Exhaust humidity | U_WORD | 0.1¹ | % | Same scaling note as 4037. |
| 4050 | Bypass state | S_WORD enum | – | – | 5-state enum (table below). |
| 4081 | Outdoor temperature (intake / NTC1) | S_WORD | 0.1 | °C | Outside air entering the unit. |
| 4100 | Filter status | U_WORD enum | – | – | 0 = clean, 1 = dirty (replace). |

¹ Per the UWA2-B docs the humidity value is in tenths of percent (range 0–1000). Empirically on this Flair 325 the register holds the value already in percent, so no `multiply: 0.1` is applied. If you see implausibly high humidity in HA, add the multiplier.

The Flair 325 does **not** have a sensor for return air between the house and the unit — heat-recovery efficiency must be estimated from outdoor↔exhaust temperature delta.

## Holding registers (6xxx) — read/write parameters

| Address | Name | Type | Range | Notes |
|--------:|---|---|---|---|
| 6000 | Flow preset 0 (Holiday) | U_WORD | 0–325 m³/h, step 5 | m³/h setpoint when 8001 = 0. Confirmed in UWA2-B docs page 11; the HA community thread misses it. |
| 6001 | Flow preset 1 (Low) | U_WORD | 50–325 m³/h, step 5 | Each preset N ≥ preset N-1. |
| 6002 | Flow preset 2 (Normal) | U_WORD | 50–325 m³/h, step 5 | |
| 6003 | Flow preset 3 (High) | U_WORD | 50–325 m³/h, step 5 | |
| **6035** | _Inflow imbalance_ (community) **OR** Flow type (UWA2-B docs) | S/U_WORD | -15…+15 % **OR** 0/1/2 | **Conflict.** Community thread says inflow imbalance offset; UWA2-B docs say flow type enum (0=Constant PWM / 1=Constant flow / 2=Constant massFlow). On this unit the register reads 0 idle, which is consistent with both. The YAML treats it as imbalance per the community pattern; do not move the slider unless you've verified the meaning on your hardware. |
| **6036** | _Outflow imbalance_ (community) **OR** Switch default position (UWA2-B docs) | S/U_WORD | -15…+15 % **OR** 0–3 | Same conflict as 6035. UWA2-B docs say "default position of the 4-position switch" (0=Holiday … 3=High). Reads 0 on this unit. |
| 6100 | Bypass mode | U_WORD enum | 0=Auto / 1=Closed / 2=Open | Empirically works on this Flair 325. UWA2-B docs are unclear about the exact address for this enum but the community thread's mapping is consistent with observed behaviour. |
| 6104 | Bypass boost | bit | 0/1 | Switch in HA. Per UWA2-B docs the bypass opens and the fan runs at a preset setting when this is on. |

## Remote control registers (8xxx) — commands

| Address | Name | Type | Range | Notes |
|--------:|---|---|---|---|
| 8000 | Modbus control mode | U_WORD enum | 0=off (LCD/manual) / 1=switch (Step) / 2=flow rate value (Flow) | Reading returns the **last accepted** value (per docs). On this Flair 325 without UWA2-B all three values are accepted on the bus but Unit mode (4020) stays at `Manual` (4) — see UWA2-B limitation below. |
| 8001 | Ventilation step (request) | U_WORD enum | 0=Holiday / 1=Low / 2=Normal / 3=High | Active when 8000 = 1 (switch). Reading returns the last accepted request. |
| 8002 | Flow setpoint (request) | U_WORD | `{0, min_flow..max_flow}` | Active when 8000 = 2. The docs note `Typ HRA: 0; min. flow - max. flow` — i.e. **0 is allowed as an "extra" off value**, then a contiguous range from the unit's minimum flow to its maximum. On the Flair 325 the range is `{0, 50..325}` m³/h; values 1–49 are rejected with Modbus exception 3 (ILLEGAL_DATA_VALUE), confirmed empirically. The YAML slider exposes only 50..325 to keep the UX clean. |
| 8010 | Standby request | U_WORD | 0=No action / 1=Set to standby / 2=Resume | Read returns the actual standby status. |
| 8011 | Filter / appliance reset | U_WORD | 0=No reset / 1=Reset filter warning / 1=Appliance reset | Self-clearing — once read the value resets to 0. Two separate registers per the docs (filter reset and appliance reset), exact address pair to verify. Not currently exposed in this project. |

## UWA2-B limitation (this unit)

This Flair 325 has Modbus enabled in the menu but **no UWA2-B expansion card**. Despite that, most of the Modbus map is fully functional, including direct fan-speed control via Flow mode.

What works (verified on this unit):

- All status sensor reads (4xxx via FC 0x04)
- Flow level setpoints (6000–6003) — change m³/h-per-step
- Bypass mode and Bypass boost (6100, 6104)
- **Flow mode control** — set `8000 = 2` (Flow) and write the desired flow to `8002`; the unit changes fan speed accordingly (range `{0, 50..325}` m³/h on the Flair 325)

What does **not** work without UWA2-B:

- **Step mode control** — writing `8001` while `8000 = 1` (Step) is acknowledged on the bus, but the unit silently flips Unit mode (4020) to `Manual` (4) and the fans don't change. Use Flow mode instead.

So the practical workflow on a bare Flair 325 is: **`Modbus control mode → Flow`, then drive the `Flow setpoint` slider from HA**. Step mode is best left to units with the UWA2-B installed.

The 8001 / 8002 registers stay exposed as `number` (writable) in the YAML — Flow setpoint actually works, and Ventilation step is correct in shape so it'll work the day a UWA2-B is added.

## Enum decoding

### 4020 Unit mode (HRA active function)

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
| 13 | Auto LAN/WLAN Portal |
| 14 | Auto LAN/WLAN Local |

Observed on this unit:

- `4 = Manual` ✓ when 8000 = LCD or after any 8001 write (the unit drops back to Manual)
- `12 = Auto Modbus` ✓ briefly seen at boot before the first 8001 write

### 4050 Bypass state

Per UWA2-B docs:

| Value | Docs label | Interpretation in this project |
|---:|---|---|
| 0 | initialize | Initialize |
| 1 | open | Opening (transient) |
| 2 | close | Closing (transient) |
| 3 | open | Open (settled) |
| 4 | closed | Closed (settled) |

The docs use both `open` for 1 and 3 and `close`/`closed` for 2 and 4 — looks like 1/2 are transitional states (motor running) and 3/4 are settled positions.

Observed on this unit:

- `3 = Open` ✓ — confirmed against the unit's LCD readout
- `4 = Closed` ✓ — observed once the bypass closed during normal operation

## Validation log

This Flair 325 has Modbus enabled in the menu, **no UWA2-B card installed**.

| Date | Register | FC | Read | Write | Notes |
|---|---|---:|---|---|---|
| 2026-05-08 | 4020 Unit mode | 0x04 | ✓ | – | enum confirmed (`12 Auto Modbus` at boot, `4 Manual` after 8001 write) |
| 2026-05-08 | 4032 Supply airflow | 0x04 | ✓ (0 idle) | – | |
| 2026-05-08 | 4036 Supply temp | 0x04 | ✓ (25.5 °C) | – | |
| 2026-05-08 | 4037 Supply humidity | 0x04 | ✓ (41) | – | reads in plain %, no multiplier needed |
| 2026-05-08 | 4042 Exhaust airflow | 0x04 | ✓ (0 idle) | – | |
| 2026-05-08 | 4046 Exhaust temp | 0x04 | ✓ (22.9 °C) | – | |
| 2026-05-08 | 4047 Exhaust humidity | 0x04 | ✓ (37) | – | |
| 2026-05-08 | 4050 Bypass state | 0x04 | ✓ (3 Open, 4 Closed) | – | |
| 2026-05-08 | 4081 Outdoor temp | 0x04 | ✓ (20.7 °C) | – | |
| 2026-05-08 | 4100 Filter status | 0x04 | ✓ (0 clean) | – | |
| 2026-05-08 | 6000 Flow preset 0 (Holiday) | 0x03 | _to verify_ | _untested_ | added 2026-05-08 after PDF cross-check |
| 2026-05-08 | 6001 Flow level 1 | 0x03 | ✓ (100 m³/h) | _untested_ | |
| 2026-05-08 | 6002 Flow level 2 | 0x03 | ✓ (150 m³/h) | _untested_ | |
| 2026-05-08 | 6003 Flow level 3 | 0x03 | ✓ (250 m³/h) | _untested_ | |
| 2026-05-08 | 6035 (community label "imbalance") | 0x03 | ✓ (0) | _untested_ | meaning ambiguous — see table above |
| 2026-05-08 | 6036 (community label "imbalance") | 0x03 | ✓ (0) | _untested_ | meaning ambiguous |
| 2026-05-08 | 6100 Bypass mode | 0x03 | ✓ (Auto) | _untested_ | |
| 2026-05-08 | 6104 Bypass boost | 0x03 | ✓ (Off) | _untested_ | |
| 2026-05-08 | 8000 Modbus control mode | 0x03 | ✓ (Step) | ⚠ accepted on bus but no behavioural effect (no UWA2-B) |
| 2026-05-08 | 8001 Ventilation step | 0x03 | ✓ | ⚠ ACK on bus, fans do not move (no UWA2-B) |
| 2026-05-08 | 8002 Flow setpoint | 0x03 | ✓ | ⚠ ACK on bus, fans do not move (no UWA2-B) |
