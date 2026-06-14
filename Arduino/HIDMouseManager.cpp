#include "HIDMouseManager.h"
#include "Config.h"

HIDMouseManager::HIDMouseManager()
  : _ready(false) {}

void HIDMouseManager::begin() {
  _mouse.begin();
  // USB.begin() is called once in main setup(); the mouse just registers itself.
  // We wait a fixed period so Windows finishes HID enumeration before we move.
  delay(Config::USB_READY_DELAY_MS);
  _ready = true;
}

bool HIDMouseManager::isReady() const {
  return _ready;
}

void HIDMouseManager::moveLarge(int totalDx, int totalDy) {
  if (!_ready) return;

  // Walk both axes in lock-step so the cursor travels roughly diagonally.
  // Each iteration sends one HID report covering up to HID_STEP_SIZE in each axis.
  while (totalDx != 0 || totalDy != 0) {
    int stepX = 0;
    int stepY = 0;

    if (totalDx > 0) {
      stepX   = min(totalDx, Config::HID_STEP_SIZE);
      totalDx -= stepX;
    } else if (totalDx < 0) {
      stepX   = max(totalDx, -Config::HID_STEP_SIZE);
      totalDx -= stepX;
    }

    if (totalDy > 0) {
      stepY   = min(totalDy, Config::HID_STEP_SIZE);
      totalDy -= stepY;
    } else if (totalDy < 0) {
      stepY   = max(totalDy, -Config::HID_STEP_SIZE);
      totalDy -= stepY;
    }

    // move() accepts int8_t; the clamping above keeps values in ±127.
    _mouse.move(static_cast<int8_t>(stepX), static_cast<int8_t>(stepY), 0);
    delay(Config::STEP_DELAY_MS);
  }
}

void HIDMouseManager::leftClick() {
  if (!_ready) return;
  _mouse.click(MOUSE_LEFT);
}
