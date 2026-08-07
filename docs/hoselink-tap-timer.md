# Hoselink Tap Timer → Local Home Assistant Control

## Goal

Get the Hoselink dual-outlet Bluetooth tap timer off the Tuya **cloud**
integration (unreliable, requires periodic re-authentication) and onto a
**local** control path in Home Assistant.

## Hardware & Tuya identifiers

- **Timer:** Hoselink dual-outlet Bluetooth tap timer.
  - `product_id`: `qycalacn`
  - `category`: `ggq` (Tuya irrigation / valve-controller class)
  - Bluetooth-only — no WiFi radio, no LAN presence of its own.
- **Gateway:** Hoselink WiFi Gateway — the only device with a LAN IP.
  Bridges the timer's BLE to WiFi/cloud.

## Key finding: the gateway is a dumb passthrough

The gateway's data model exposes **only** two datapoints:

- DP 1 `up_channel` (raw, 128 B, read-only)
- DP 2 `down_channel` (raw, 128 B, write-only)

It does **not** re-expose the timer's datapoints addressably over the LAN.
The timer's real DPs are tunnelled as encoded BLE payloads inside those raw
frames. This is the classic pattern behind "connection succeeded but no
datapoints found" when adding a Tuya BLE sub-device through a hub.

## Timer datapoint model (from Query Things Data Model)

| DP  | Code                | Type                     | RW | Intended HA entity |
|-----|---------------------|--------------------------|----|--------------------|
| 105 | switch_1            | bool                     | rw | switch (outlet 1)  |
| 104 | switch_2            | bool                     | rw | switch (outlet 2)  |
| 106 | countdown_1         | value 0–1440 min         | rw | number             |
| 103 | countdown_2         | value 0–1440 min         | rw | number             |
| 11  | battery_percentage  | value 0–100 %            | ro | sensor             |
| 111 | use_time_1          | value 0–86400 s          | ro | sensor             |
| 110 | use_time_2          | value 0–86400 s          | ro | sensor             |
| 112 | status_1            | enum manual/auto/idle    | ro | sensor             |
| 113 | status_2            | enum manual/auto/idle    | ro | sensor             |
| 117 | weather_delay       | enum OFF/1–7             | rw | select (disabled by default) |
| 114 | weather_delay2      | enum OFF/1–7             | rw | select (disabled by default) |
| 19  | fault               | bitmap (len 2)           | ro | binary_sensor      |
| 101 | normal_timer        | raw 128 B                | rw | ignore (schedule)  |
| 102 | cycle_timer         | raw 128 B                | rw | ignore (cycle)     |

Both outlets have independent switches, countdowns, status and usage sensors.
Countdowns are in minutes and close an open outlet on expiry; they do not open a
closed outlet. Manual switching and countdown shutoff were tested successfully
with weather delay set to one day.

Schedules (DP 101/102) are not supported. Weather-delay controls (DP 117/114)
are therefore disabled by default: their effect on device schedules is unverified, and
they do not prevent manual watering or countdown shutoff. Use the official app
to manage device schedules and weather delays.

The controls can be enabled through Settings > Devices & services > Entities.
Existing entities retain their enabled state; disable them there if desired.
Disabling the entities does not change the timer's existing weather-delay settings.

### Raw data

#### Timer Product Info

```text
"name": "Smart Dual Water  Timer",
"product_id": "qycalacn",
"product_name": "一出二水阀V2",
"category": "ggq",
```

#### Timer datapoint model

```json
{
  "result": {
    "model": "{\"modelId\":\"ej5kng\",\"services\":[{\"actions\":[],\"code\":\"\",\"description\":\"\",\"events\":[],\"name\":\"默认服务\",\"properties\":[{\"abilityId\":11,\"accessMode\":\"ro\",\"code\":\"battery_percentage\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_battery\",\"attribute\":\"1024\"},\"name\":\"主电池电量\",\"typeSpec\":{\"type\":\"value\",\"max\":100,\"min\":0,\"scale\":0,\"step\":1,\"unit\":\"%\"}},{\"abilityId\":19,\"accessMode\":\"ro\",\"code\":\"fault\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-baojing\",\"scope\":\"fault\",\"attribute\":\"1024\"},\"name\":\"故障告警\",\"typeSpec\":{\"type\":\"bitmap\",\"label\":[\"1\",\"2\"],\"maxlen\":2}},{\"abilityId\":101,\"accessMode\":\"rw\",\"code\":\"normal_timer\",\"description\":\"\",\"name\":\"普通定时\",\"typeSpec\":{\"type\":\"raw\",\"maxlen\":128}},{\"abilityId\":102,\"accessMode\":\"rw\",\"code\":\"cycle_timer\",\"description\":\"\",\"name\":\"循环定时\",\"typeSpec\":{\"type\":\"raw\",\"maxlen\":128}},{\"abilityId\":103,\"accessMode\":\"rw\",\"code\":\"countdown_2\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_time2\",\"attribute\":\"4096\"},\"name\":\"开关2倒计时\",\"typeSpec\":{\"type\":\"value\",\"max\":1440,\"min\":0,\"scale\":0,\"step\":1,\"unit\":\"min\"}},{\"abilityId\":104,\"accessMode\":\"rw\",\"code\":\"switch_2\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_power2\",\"attribute\":\"4096\"},\"name\":\"开关2\",\"typeSpec\":{\"type\":\"bool\"}},{\"abilityId\":105,\"accessMode\":\"rw\",\"code\":\"switch_1\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_power2\",\"attribute\":\"4096\"},\"name\":\"开关1\",\"typeSpec\":{\"type\":\"bool\"}},{\"abilityId\":106,\"accessMode\":\"rw\",\"code\":\"countdown_1\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_time2\",\"attribute\":\"4096\"},\"name\":\"开关1倒计时\",\"typeSpec\":{\"type\":\"value\",\"max\":1440,\"min\":0,\"scale\":0,\"step\":1,\"unit\":\"min\"}},{\"abilityId\":110,\"accessMode\":\"ro\",\"code\":\"use_time_2\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_time3\",\"attribute\":\"4096\",\"trigger\":\"direct\"},\"name\":\"使用时间2\",\"typeSpec\":{\"type\":\"value\",\"max\":86400,\"min\":0,\"scale\":0,\"step\":1,\"unit\":\"s\"}},{\"abilityId\":111,\"accessMode\":\"ro\",\"code\":\"use_time_1\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_time3\",\"attribute\":\"4096\",\"trigger\":\"direct\"},\"name\":\"使用时间1\",\"typeSpec\":{\"type\":\"value\",\"max\":86400,\"min\":0,\"scale\":0,\"step\":1,\"unit\":\"s\"}},{\"abilityId\":112,\"accessMode\":\"ro\",\"code\":\"status_1\",\"description\":\"\",\"name\":\"状态1\",\"typeSpec\":{\"type\":\"enum\",\"range\":[\"manual\",\"auto\",\"idle\"]}},{\"abilityId\":113,\"accessMode\":\"ro\",\"code\":\"status_2\",\"description\":\"\",\"name\":\"状态2\",\"typeSpec\":{\"type\":\"enum\",\"range\":[\"manual\",\"auto\",\"idle\"]}},{\"abilityId\":114,\"accessMode\":\"rw\",\"code\":\"weather_delay2\",\"description\":\"\",\"name\":\"天气延时2\",\"typeSpec\":{\"type\":\"enum\",\"range\":[\"OFF\",\"1\",\"2\",\"3\",\"4\",\"5\",\"6\",\"7\"]}},{\"abilityId\":117,\"accessMode\":\"rw\",\"code\":\"weather_delay\",\"description\":\"\",\"extensions\":{\"iconName\":\"icon-dp_light2\",\"attribute\":\"4096\"},\"name\":\"天气延时\",\"typeSpec\":{\"type\":\"enum\",\"range\":[\"OFF\",\"1\",\"2\",\"3\",\"4\",\"5\",\"6\",\"7\"]}}]}]}"
  },
  "success": true,
  "t": 1782396637695,
  "tid": "a3d5caae709f11f180fff665632ead7a"
}
```

#### Gateway datapoint model

```json
{
  "result": {
    "model": "{\"modelId\":\"0000030kxe\",\"services\":[{\"actions\":[],\"code\":\"\",\"description\":\"\",\"events\":[],\"name\":\"默认服务\",\"properties\":[{\"abilityId\":1,\"accessMode\":\"ro\",\"code\":\"up_channel\",\"description\":\"数据传输上行通道\",\"extensions\":{\"iconName\":\"icon-dp_mode\",\"attribute\":\"640\"},\"name\":\"上行通道\",\"typeSpec\":{\"type\":\"raw\",\"maxlen\":128}},{\"abilityId\":2,\"accessMode\":\"wr\",\"code\":\"down_channel\",\"description\":\"数据传输下行通道\",\"extensions\":{\"iconName\":\"icon-dp_mode\",\"attribute\":\"640\"},\"name\":\"下行通道\",\"typeSpec\":{\"type\":\"raw\",\"maxlen\":128}}]}]}"
  },
  "success": true,
  "t": 1782396689113,
  "tid": "c280954d709f11f1a3fc1af992f77835"
}
```
