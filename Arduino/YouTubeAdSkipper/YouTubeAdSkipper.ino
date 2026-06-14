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
 *
 * Required Arduino IDE board settings (Tools menu):
 *   Flash Mode        : QIO 80MHz   (NOT OPI — board does not have Octal flash)
 *   Flash Size        : 16MB (128Mb)
 *   Partition Scheme  : 16M Flash (3MB APP/9.9MB FATFS)
 *   PSRAM             : Disabled
 *   USB Mode          : USB-OTG (TinyUSB)
 *   USB CDC On Boot   : Disabled
 *   Upload Mode       : UART0 / Hardware CDC
 *
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
  // Give Serial time to connect before logging anything.
  vTaskDelay(pdMS_TO_TICKS(500));
  Serial.println("[Main] Serial ready.");

  // USB.begin() must be called before any HID begin().
  Serial.println("[Main] Starting USB...");
  USB.begin();

  // Initialise HID mouse — waits for USB enumeration via vTaskDelay (WDT-safe).
  Serial.println("[Main] Starting HID mouse...");
  hidMouse.begin();

  // Initialise BLE server and start advertising.
  Serial.println("[Main] Starting BLE...");
  bleManager.begin();

  Serial.println("[Main] Setup complete. Waiting for BLE commands.");
}

void loop() {
  // Allow BLEManager to restart advertising after a client disconnects.
  bleManager.update();

  // Small yield so the BLE stack can process events.
  delay(10);
}
