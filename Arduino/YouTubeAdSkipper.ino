/**
 * YouTubeAdSkipper
 *
 * ESP32-S3 firmware that:
 *  - Enumerates as a USB HID mouse (native USB peripheral, no USB-serial).
 *  - Exposes a BLE GATT service so an Android app can send command bytes.
 *  - Executes mouse macros on command: slam to bottom-right corner, offset,
 *    click — mapping to screen targets regardless of prior cursor position.
 *
 * Board target : ESP32-S3 DevKitC-1 (esp32s3) in the Arduino IDE / PlatformIO.
 * Required libraries:
 *   - ESP32 Arduino core ≥ 2.0.11  (includes USB.h, USBHIDMouse.h, BLE*)
 *
 * USB note:
 *   In Arduino IDE board settings set "USB Mode" to "USB-OTG (TinyUSB)" or
 *   "Hardware CDC and OTG" — NOT "UART0/Hardware CDC".  The native USB
 *   peripheral must be active for HID to enumerate.
 */

#include "USB.h"          // Must be first — configures the USB stack.
#include "Config.h"
#include "HIDMouseManager.h"
#include "MacroManager.h"
#include "BLEManager.h"

// ── Module instances ──────────────────────────────────────────────────────────

HIDMouseManager hidMouse;
MacroManager    macroManager(hidMouse);
BLEManager      bleManager(macroManager);

// ── Arduino entry points ──────────────────────────────────────────────────────

void setup() {
  Serial.begin(115200);

  // USB.begin() must be called before any HID begin().
  USB.begin();

  // Initialise HID mouse — internally waits for USB enumeration.
  hidMouse.begin();

  // Initialise BLE server and start advertising.
  bleManager.begin();

  Serial.println("[Main] Setup complete.  Waiting for BLE commands.");
}

void loop() {
  // Allow BLEManager to restart advertising after a client disconnects.
  bleManager.update();

  // Small yield so the BLE stack can process events.
  delay(10);
}
