#include "MacroManager.h"
#include "Config.h"

MacroManager::MacroManager(HIDMouseManager& mouse)
  : _mouse(mouse), _busy(false) {}

bool MacroManager::isBusy() const {
  return _busy;
}

bool MacroManager::executeMacro(uint8_t command) {
  if (!_mouse.isReady()) {
    Serial.println("[MacroManager] HID not ready — ignoring command.");
    return false;
  }
  if (_busy) {
    Serial.println("[MacroManager] Macro already running — ignoring command.");
    return false;
  }

  switch (command) {
    case 0x01: macro1(); return true;
    case 0x02: macro2(); return true;
    case 0x03: macro3(); return true;
    default:
      Serial.printf("[MacroManager] Unknown command: 0x%02X\n", command);
      return false;
  }
}

// ── Shared helper ─────────────────────────────────────────────────────────────

void MacroManager::moveToBottomRight() {
  // Overshoot in both axes simultaneously; any modern 4K monitor fits within 5000 px.
  _mouse.moveLarge(Config::CORNER_MOVE_RIGHT, Config::CORNER_MOVE_DOWN);
  delay(Config::CORNER_SETTLE_MS);
}

// ── Macro implementations ─────────────────────────────────────────────────────

void MacroManager::macro1() {
  _busy = true;
  Serial.println("[MacroManager] Executing Macro 1");

  moveToBottomRight();

  // Move to target offset from corner (left and up = negative direction).
  _mouse.moveLarge(-Config::MACRO1_LEFT, -Config::MACRO1_UP);
  delay(Config::PRE_CLICK_DELAY_MS);

  _mouse.leftClick();

  Serial.println("[MacroManager] Macro 1 complete");
  _busy = false;
}

void MacroManager::macro2() {
  _busy = true;
  Serial.println("[MacroManager] Executing Macro 2");

  moveToBottomRight();
  _mouse.moveLarge(-Config::MACRO2_LEFT, -Config::MACRO2_UP);
  delay(Config::PRE_CLICK_DELAY_MS);

  _mouse.leftClick();

  Serial.println("[MacroManager] Macro 2 complete");
  _busy = false;
}

void MacroManager::macro3() {
  _busy = true;
  Serial.println("[MacroManager] Executing Macro 3");

  moveToBottomRight();
  _mouse.moveLarge(-Config::MACRO3_LEFT, -Config::MACRO3_UP);
  delay(Config::PRE_CLICK_DELAY_MS);

  _mouse.leftClick();

  Serial.println("[MacroManager] Macro 3 complete");
  _busy = false;
}
