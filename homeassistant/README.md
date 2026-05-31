# Home Assistant automations

Control logic that runs **in Home Assistant** on top of the ESPHome Modbus
integration:

1. **CO2-based ventilation** — drives the unit in **Flow mode** (register
   `8002`), mapping the *highest* CO2 across all four room sensors (Lada,
   Ložnice, Lucka, Obývák) linearly to a flow setpoint in m³/h. Whoever is
   stuffiest sets the pace ("worst room wins").
2. **Whole-house night/morning free cooling** — opens the **bypass** (register
   `6100`) when the house is warm and it is cooler outside, flushing the house
   with cool night/morning air; returns to Auto once the house has cooled or
   the outdoor advantage is gone.

Everything ships as a single Home Assistant **package**:
[`packages/brink_flair_control.yaml`](packages/brink_flair_control.yaml).

## Wired-in entities

Entity IDs are already filled in (pulled from the live instance), so no editing
is required:

| Role | Entity IDs |
|---|---|
| CO2 (ppm) | `sensor.co2_lada_co2`, `sensor.co2_loznice_co2`, `sensor.co2_lucka_co2`, `sensor.co2` |
| House temp (cooling) | `sensor.brink_flair_325_exhaust_temperature_to_outside` (reg 4046) |
| Outdoor temp | `sensor.brink_flair_325_outdoor_temperature_intake` (reg 4081) |
| Flow setpoint | `number.brink_flair_325_flow_setpoint` |
| Control mode | `select.brink_flair_325_modbus_control_mode` |
| Bypass mode | `select.brink_flair_325_bypass_mode` |

Unavailable/unknown CO2 sensors are skipped automatically, so a single offline
room sensor will not break the aggregation.

> **The room CO2 sensors are NOT used for temperature.** Their built-in ESP32
> self-heats and inflates the temperature reading by ~4–5 °C (e.g. 28–30 °C
> shown while a wall thermostat reads 23.5 °C). Their CO2 (ppm) reading is fine.

## Install

1. Enable packages once in `configuration.yaml`:

   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```

2. Copy `packages/brink_flair_control.yaml` into your HA `<config>/packages/`
   directory.

3. Restart Home Assistant (or **Developer Tools → YAML → Check config**, then
   reload). The automations and helpers appear automatically; both master
   switches default to **on**.

## Tuning (no YAML editing needed)

| Helper | Default | Purpose |
|---|---|---|
| `input_boolean.brink_co2_control_enable` | on | Master switch for CO2 ventilation |
| `input_boolean.brink_bypass_cooling_enable` | on | Master switch for night cooling |
| `input_number.brink_co2_min_ppm` | 600 | CO2 at which flow = min |
| `input_number.brink_co2_max_ppm` | 1500 | CO2 at which flow = max |
| `input_number.brink_flow_min` | 50 | Minimum flow (unit floor is 50 m³/h) |
| `input_number.brink_flow_max` | 325 | Maximum flow (unit ceiling) |
| `input_number.brink_cooling_flow` | 250 | Flow while night cooling holds the bypass open |
| `input_number.brink_bypass_open_above` | 21.5 | Open bypass above this house temp¹ |
| `input_number.brink_bypass_close_below` | 20 | Close bypass below this house temp¹ |
| `input_number.brink_bypass_outdoor_margin` | 1.0 | Required outdoor advantage (°C) to open |
| `input_datetime.brink_bypass_start` | 19:00 | Cooling window start |
| `input_datetime.brink_bypass_end` | 09:00 | Cooling window end |

¹ Measured on the **unit exhaust sensor (reg 4046)** scale — see below.

## How it behaves

**CO2 ventilation.** `co2 = max(all room sensors)`, then
`flow = clamp(flow_min + (co2 − co2_min)/(co2_max − co2_min) × (flow_max −
flow_min))`, rounded to 25 m³/h steps so the fan does not chase every ppm
wobble. Re-asserted every 5 minutes — which also restores Flow mode and the
setpoint after a unit power cycle (the unit forgets registers 8000–8002 on
mains loss, see [../docs/registers.md](../docs/registers.md)).

> Verified live: rooms at 694–1088 ppm → `max = 1088 ppm` → **200 m³/h**.

**Free cooling.** Inside the time window, opens the bypass when
`house > open_above AND outdoor < house − margin`. Closes (back to Auto) when
`house ≤ close_below`, the outdoor advantage disappears, or the window ends.
The open/close split is deliberate hysteresis to avoid flapping.

### Why the unit exhaust (4046), not room sensors

The room CO2 sensors over-report temperature (ESP32 self-heating, see above),
and the Flair 325 has **no dedicated return-air sensor**
([../docs/registers.md](../docs/registers.md)). The exhaust-air temperature
(reg 4046) is the mixed extract air from the whole house, so it is the best
whole-house figure the unit offers — and the user confirmed it tracks reality
well (~1–2 °C below a wall thermostat).

**Self-correcting quirk:** 4046 sits behind the heat exchanger, so while the
bypass is **closed** it reads ~1–2 °C *below* true house temp. The instant the
bypass **opens**, the extract air bypasses the exchanger and 4046 jumps to the
true house temperature. So the loop opens a touch eagerly, then the now-accurate
4046 either confirms (stays open and cools) or triggers an early close (house
was already cool). Thresholds are therefore tuned on the 4046 scale, not on a
"real room temperature" scale.

> Verified live (night): house 4046 = 22.2 °C, outdoor = 20.9 °C → would open.

## Cooling boost (flow during night cooling)

Free cooling only moves as much heat as the airflow carries, so while the
bypass is open the CO2 automation raises the flow to
`input_number.brink_cooling_flow` (default **250 m³/h**) — overriding the
CO2-driven value. This is done **inside the CO2 automation**, which therefore
remains the single writer of the flow setpoint; the two features never fight
over `number.brink_flair_325_flow_setpoint`.

The boost is active only while *all* hold: night cooling enabled, the bypass is
`Open`, the time is inside the window, and it is still cooler outside
(`outdoor < house`). When the bypass closes, the flow falls straight back to
the CO2-driven value. Lower `brink_cooling_flow` if the fan is too loud at
night, or raise it (up to 325) for more aggressive cooling.
