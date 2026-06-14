#pragma once

/**
 * Config.h
 * Central location for all configurable constants.
 * Adjust movement distances and timing here without touching program logic.
 */

namespace Config {

  // ── BLE ────────────────────────────────────────────────────────────────────
  constexpr const char* BLE_DEVICE_NAME   = "ESP32-HID-Controller";
  // Use a UUID generator (e.g. https://www.uuidgenerator.net/) if you need uniqueness.
  constexpr const char* SERVICE_UUID      = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  constexpr const char* COMMAND_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // ── Mouse movement ─────────────────────────────────────────────────────────
  // Large initial moves that push the cursor into the bottom-right corner.
  // 5000 pixels safely overshoots any realistic monitor resolution.
  constexpr int CORNER_MOVE_RIGHT = 5000;
  constexpr int CORNER_MOVE_DOWN  = 5000;

  // Maximum signed delta per HID report packet.
  // USB HID mouse reports use int8_t, so the hardware limit is ±127.
  // We cap at 100 to leave headroom and keep movement smooth.
  constexpr int HID_STEP_SIZE = 100;

  // Milliseconds between consecutive HID movement packets.
  // Too short → Windows drops packets; 5 ms is reliable in practice.
  constexpr int STEP_DELAY_MS = 5;

  // Milliseconds to wait after reaching the corner before the offset move.
  // Needs to be long enough for Windows to process all buffered HID packets.
  constexpr int CORNER_SETTLE_MS = 300;

  // Milliseconds to wait after the offset move before clicking.
  constexpr int PRE_CLICK_DELAY_MS = 30;

  // ── Command bytes ──────────────────────────────────────────────────────────
  // Sent as first byte of every BLE packet.
  // Macro commands (0x01-0x03): 5 bytes total [cmd, x_high, x_low, y_high, y_low]
  //   x/y are the pixel offset LEFT and UP from the bottom-right corner.
  // Setup commands (0x10, 0x11): used by the phone's macro setup page.
  constexpr uint8_t CMD_MACRO1        = 0x01;
  constexpr uint8_t CMD_MACRO2        = 0x02;
  constexpr uint8_t CMD_MACRO3        = 0x03;
  constexpr uint8_t CMD_GOTO_CORNER   = 0x10; // Move to bottom-right, no click
  constexpr uint8_t CMD_RELATIVE_MOVE = 0x11; // 5 bytes: [0x11, dx_high, dx_low, dy_high, dy_low]

  // ── Macro 1 target offset from bottom-right corner ─────────────────────────
  constexpr int MACRO1_LEFT = 160;
  constexpr int MACRO1_UP   = 70;

  // ── Macro 2 target offset from bottom-right corner ─────────────────────────
  constexpr int MACRO2_LEFT = 300;
  constexpr int MACRO2_UP   = 150;

  // ── Macro 3 target offset from bottom-right corner ─────────────────────────
  constexpr int MACRO3_LEFT = 500;
  constexpr int MACRO3_UP   = 200;

  // ── USB readiness ──────────────────────────────────────────────────────────
  // Milliseconds to wait after USB.begin() before treating HID as enumerated.
  constexpr int USB_READY_DELAY_MS = 2000;

} // namespace Config
