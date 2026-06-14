#pragma once

#include "USB.h"
#include "USBHIDMouse.h"

/**
 * HIDMouseManager
 * Owns the USBHIDMouse instance and provides helper methods for
 * large relative movements that exceed the ±127 int8_t HID limit.
 */
class HIDMouseManager {
public:
  HIDMouseManager();

  // Must be called in setup() before any movement.
  void begin();

  // Returns true once USB HID has been given time to enumerate.
  bool isReady() const;

  /**
   * Move the cursor by (totalDx, totalDy) pixels, automatically
   * splitting the journey into HID_STEP_SIZE chunks with STEP_DELAY_MS
   * pauses so Windows receives every packet reliably.
   * Positive dx = right; positive dy = down.
   */
  void moveLarge(int totalDx, int totalDy);

  // Single left-click.
  void leftClick();

private:
  USBHIDMouse _mouse;
  bool        _ready;

  // Send one clamped HID report and advance remaining distance.
  void sendStep(int& remaining, bool isX);
};
