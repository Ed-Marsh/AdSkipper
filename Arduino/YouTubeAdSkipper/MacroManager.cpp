#include "MacroManager.h"
#include "Config.h"

MacroManager::MacroManager(HIDMouseManager& mouse)
  : _mouse(mouse), _busy(false) {}

bool MacroManager::isBusy() const {
  return _busy;
}

int16_t MacroManager::decodeInt16(uint8_t high, uint8_t low) {
  return static_cast<int16_t>((high << 8) | low);
}

bool MacroManager::executeCommand(const uint8_t* data, size_t length) {
  if (length == 0) {
    Serial.println("[MacroManager] Empty packet — ignoring.");
    return false;
  }

  if (!_mouse.isReady()) {
    Serial.println("[MacroManager] HID not ready — ignoring command.");
    return false;
  }

  if (_busy) {
    Serial.println("[MacroManager] Busy — ignoring command.");
    return false;
  }

  uint8_t cmd = data[0];
  Serial.printf("[MacroManager] Command: 0x%02X  length: %d\n", cmd, length);

  switch (cmd) {

    // ── Macro commands: 5 bytes [cmd, x_high, x_low, y_high, y_low] ─────────
    case Config::CMD_MACRO1:
    case Config::CMD_MACRO2:
    case Config::CMD_MACRO3: {
      if (length < 5) {
        Serial.printf("[MacroManager] Macro command needs 5 bytes, got %d — ignoring.\n", length);
        return false;
      }
      int offsetLeft = decodeInt16(data[1], data[2]);
      int offsetUp   = decodeInt16(data[3], data[4]);
      Serial.printf("[MacroManager] Macro %d: offsetLeft=%d offsetUp=%d\n",
        cmd, offsetLeft, offsetUp);
      runMacro(offsetLeft, offsetUp);
      return true;
    }

    // ── Go to corner: 1 byte — setup mode entry ───────────────────────────────
    case Config::CMD_GOTO_CORNER: {
      _busy = true;
      Serial.println("[MacroManager] CMD_GOTO_CORNER");
      moveToBottomRight();
      _busy = false;
      return true;
    }

    // ── Relative move: 5 bytes [cmd, dx_high, dx_low, dy_high, dy_low] ───────
    case Config::CMD_RELATIVE_MOVE: {
      if (length < 5) {
        Serial.printf("[MacroManager] Relative move needs 5 bytes, got %d — ignoring.\n", length);
        return false;
      }
      _busy = true;
      int16_t dx = decodeInt16(data[1], data[2]);
      int16_t dy = decodeInt16(data[3], data[4]);
      Serial.printf("[MacroManager] CMD_RELATIVE_MOVE dx=%d dy=%d\n", dx, dy);
      _mouse.moveLarge(dx, dy);
      _busy = false;
      return true;
    }

    default:
      Serial.printf("[MacroManager] Unknown command: 0x%02X\n", cmd);
      return false;
  }
}

void MacroManager::moveToBottomRight() {
  Serial.printf("[MacroManager] Moving to corner (%d, %d)...\n",
    Config::CORNER_MOVE_RIGHT, Config::CORNER_MOVE_DOWN);
  _mouse.moveLarge(Config::CORNER_MOVE_RIGHT, Config::CORNER_MOVE_DOWN);
  delay(Config::CORNER_SETTLE_MS);
  Serial.println("[MacroManager] Corner reached.");
}

void MacroManager::runMacro(int offsetLeft, int offsetUp) {
  _busy = true;
  Serial.println("[MacroManager] === Macro start ===");
  moveToBottomRight();
  Serial.printf("[MacroManager] Offset move: -%d, -%d\n", offsetLeft, offsetUp);
  _mouse.moveLarge(-offsetLeft, -offsetUp);
  delay(Config::PRE_CLICK_DELAY_MS);
  _mouse.leftClick();
  Serial.println("[MacroManager] === Macro complete ===");
  _busy = false;
}
