#include "MacroManager.h"
#include "Config.h"

MacroManager::MacroManager(HIDMouseManager& mouse)
  : _mouse(mouse), _busy(false) {}

bool MacroManager::isBusy() const {
  return _busy;
}

bool MacroManager::executeMacro(uint8_t command) {
  Serial.printf("[MacroManager] executeMacro called: command=0x%02X busy=%s ready=%s\n",
    command, _busy ? "true" : "false", _mouse.isReady() ? "true" : "false");

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
  Serial.printf("[MacroManager] Moving to bottom-right corner (%d, %d)...\n",
    Config::CORNER_MOVE_RIGHT, Config::CORNER_MOVE_DOWN);
  _mouse.moveLarge(Config::CORNER_MOVE_RIGHT, Config::CORNER_MOVE_DOWN);
  Serial.printf("[MacroManager] Corner reached. Settling %d ms...\n", Config::CORNER_SETTLE_MS);
  delay(Config::CORNER_SETTLE_MS);
}

// ── Macro implementations ─────────────────────────────────────────────────────

void MacroManager::macro1() {
  _busy = true;
  Serial.println("[MacroManager] === Macro 1 start ===");

  moveToBottomRight();
  Serial.printf("[MacroManager] Offset move: -%d, -%d\n", Config::MACRO1_LEFT, Config::MACRO1_UP);
  _mouse.moveLarge(-Config::MACRO1_LEFT, -Config::MACRO1_UP);
  Serial.printf("[MacroManager] Pre-click delay %d ms...\n", Config::PRE_CLICK_DELAY_MS);
  delay(Config::PRE_CLICK_DELAY_MS);
  _mouse.leftClick();

  Serial.println("[MacroManager] === Macro 1 complete ===");
  _busy = false;
}

void MacroManager::macro2() {
  _busy = true;
  Serial.println("[MacroManager] === Macro 2 start ===");

  moveToBottomRight();
  Serial.printf("[MacroManager] Offset move: -%d, -%d\n", Config::MACRO2_LEFT, Config::MACRO2_UP);
  _mouse.moveLarge(-Config::MACRO2_LEFT, -Config::MACRO2_UP);
  Serial.printf("[MacroManager] Pre-click delay %d ms...\n", Config::PRE_CLICK_DELAY_MS);
  delay(Config::PRE_CLICK_DELAY_MS);
  _mouse.leftClick();

  Serial.println("[MacroManager] === Macro 2 complete ===");
  _busy = false;
}

void MacroManager::macro3() {
  _busy = true;
  Serial.println("[MacroManager] === Macro 3 start ===");

  moveToBottomRight();
  Serial.printf("[MacroManager] Offset move: -%d, -%d\n", Config::MACRO3_LEFT, Config::MACRO3_UP);
  _mouse.moveLarge(-Config::MACRO3_LEFT, -Config::MACRO3_UP);
  Serial.printf("[MacroManager] Pre-click delay %d ms...\n", Config::PRE_CLICK_DELAY_MS);
  delay(Config::PRE_CLICK_DELAY_MS);
  _mouse.leftClick();

  Serial.println("[MacroManager] === Macro 3 complete ===");
  _busy = false;
}
