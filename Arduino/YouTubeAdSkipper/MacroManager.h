#pragma once

#include <stdint.h>
#include "HIDMouseManager.h"

/**
 * MacroManager
 * Maps byte commands received over BLE to mouse macro sequences.
 * Guards against concurrent execution with an _busy flag.
 *
 * To add a new macro:
 *   1. Add a private macroN() declaration and implement it in the .cpp.
 *   2. Add a case for the new command byte in executeMacro().
 */
class MacroManager {
public:
  explicit MacroManager(HIDMouseManager& mouse);

  /**
   * Dispatches command to the appropriate macro.
   * Returns false if the HID is not ready, a macro is already running,
   * or the command is unknown.
   */
  bool executeMacro(uint8_t command);

  bool isBusy() const;

private:
  HIDMouseManager& _mouse;
  bool             _busy;

  // Shared first step: slam cursor to bottom-right corner.
  void moveToBottomRight();

  void macro1();
  void macro2();
  void macro3();
};
