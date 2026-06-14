# AdSkipper

An ESP32-S3 based USB HID mouse controller that lets you skip YouTube ads (and trigger other mouse macros) with a tap on your Android phone via Bluetooth Low Energy.

## How it works

The ESP32-S3 enumerates as a USB HID mouse on your PC. An Android app connects to it over BLE and sends macro commands. When triggered, the ESP32 slams the cursor to the bottom-right corner of the screen (a known reference point), then moves a calibrated offset to the target position and clicks.

Each macro's target position is configured directly on the phone using a jog interface — no hardcoded coordinates in the firmware.

---

## Repository structure

```
AdSkipper/
├── Arduino/
│   └── YouTubeAdSkipper/       # ESP32-S3 firmware (Arduino IDE)
│       ├── YouTubeAdSkipper.ino
│       ├── BLEManager.cpp/h    # BLE GATT server
│       ├── HIDMouseManager.cpp/h  # USB HID mouse abstraction
│       ├── MacroManager.cpp/h  # Command dispatch and macro execution
│       └── Config.h            # All tunable constants
└── B4X/
    ├── B4A/                    # Android project (B4A)
    ├── B4XMainPage.bas         # Main screen — connect, trigger macros
    ├── MacroSetupPage.bas      # Per-macro jog/calibration screen
    └── BleManager.bas          # BLE wrapper class
```

---

## Hardware

- **ESP32-S3 DevKitC-1** (or compatible) with 16MB flash
- USB cable from ESP32 native USB port to PC (HID)
- USB cable from ESP32 UART port to PC (flashing only)
- Android phone with BLE support

---

## Arduino IDE board settings

These settings are critical — wrong values cause boot crashes:

| Setting | Value |
|---|---|
| Board | ESP32S3 Dev Module |
| Flash Mode | **QIO 80MHz** (NOT OPI) |
| Flash Size | 16MB (128Mb) |
| Partition Scheme | 16M Flash (3MB APP/9.9MB FATFS) |
| PSRAM | **Disabled** |
| USB Mode | USB-OTG (TinyUSB) |
| USB CDC On Boot | Disabled |
| Upload Mode | UART0 / Hardware CDC |

> **Note:** The board does not have Octal flash/PSRAM. Using OPI flash mode causes an `RTCWDT_RTC_RST` boot loop.

---

## BLE protocol

All commands are sent as byte arrays to the GATT write characteristic.

| Command | Bytes | Description |
|---|---|---|
| `0x01` | `[0x01, x_hi, x_lo, y_hi, y_lo]` | Run macro 1 |
| `0x02` | `[0x02, x_hi, x_lo, y_hi, y_lo]` | Run macro 2 |
| `0x03` | `[0x03, x_hi, x_lo, y_hi, y_lo]` | Run macro 3 |
| `0x10` | `[0x10]` | Move to corner (setup mode entry) |
| `0x11` | `[0x11, dx_hi, dx_lo, dy_hi, dy_lo]` | Relative move (jog during setup) |

`x`/`y` = pixels left/up from the bottom-right corner (unsigned int16, big-endian).
`dx`/`dy` = signed int16 relative move in pixels, big-endian.

### BLE UUIDs

```
Service:        4fafc201-1fb5-459e-8fcc-c5c9c331914b
Characteristic: beb5483e-36e1-4688-b7f5-ea07361b26a8  (WRITE)
```

---

## Android app

Built with **B4A** using **B4XPages**.

### Libraries required
- BLE2
- KeyValueStore
- RuntimePermissions
- Phone
- B4XPages
- Core

### Usage

1. Tap **Connect** — the app scans for `ESP32-HID-Controller` and connects automatically.
2. Tap a **macro button** to trigger that macro.
3. **Long press** a macro button to open the setup page and calibrate the target position.

### Calibrating a macro

1. Long press the macro button — the mouse jumps to the bottom-right corner.
2. Use the **Up/Down/Left/Right** buttons to jog the mouse to the target.
3. Adjust the **step size** (default 10px) for coarse or fine movement.
4. Tap **Save** — the offset is stored on the phone and used for all future macro triggers.

> **Important:** Disable **"Enhance pointer precision"** in Windows mouse settings. Mouse acceleration causes HID pixel values to be non-linear, making calibration unreliable.

---

## Config.h tuning

| Constant | Default | Description |
|---|---|---|
| `CORNER_MOVE_RIGHT` | 5000 | Pixels right to reach corner (overshoot) |
| `CORNER_MOVE_DOWN` | 5000 | Pixels down to reach corner (overshoot) |
| `HID_STEP_SIZE` | 100 | Max pixels per HID report packet |
| `STEP_DELAY_MS` | 5 | Delay between HID packets (ms) |
| `CORNER_SETTLE_MS` | 300 | Settle time after corner move (ms) |
| `PRE_CLICK_DELAY_MS` | 30 | Delay before click (ms) |
| `USB_READY_DELAY_MS` | 2000 | USB enumeration wait on boot (ms) |
