#pragma once

#include <stdint.h>
#include "HIDMouseManager.h"

/**
 * MacroManager
 * Maps byte commands received over BLE to mouse macro sequences.
 *
 * Command format:
 *   Macro (0x01-0x03) : 5 bytes [cmd, x_high, x_low, y_high, y_low]
 *                        x/y = pixels LEFT and UP from bottom-right corner.
 *                        Phone sends stored offsets so no hardcoded positions.
 *   Goto corner (0x10): 1 byte  — move to corner, no click (setup mode entry)
 *   Relative move(0x11): 5 bytes [cmd, dx_high, dx_low, dy_high, dy_low]
 *                        signed int16 dx/dy — used for nudging in setup mode.
 */
class MacroManager {
public:
  explicit MacroManager(HIDMouseManager& mouse);

  /**
   * Dispatches command to the appropriate handler.
   * data[] is the full BLE packet; length is its byte count.
   */
  bool executeCommand(const uint8_t* data, size_t length);

  bool isBusy() const;

private:
  HIDMouseManager& _mouse;
  bool             _busy;

  void moveToBottomRight();

  // Decode a signed int16 from two bytes (big-endian).
  int16_t decodeInt16(uint8_t high, uint8_t low);

  void runMacro(int offsetLeft, int offsetUp);
};
