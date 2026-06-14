#include "HIDMouseManager.h"
#include "Config.h"

HIDMouseManager::HIDMouseManager()
  : _ready(false) {}

void HIDMouseManager::begin() {
  Serial.println("[HIDMouse] begin() called.");
  _mouse.begin();
  // USB.begin() is called once in main setup(); the mouse just registers itself.
  // Use vTaskDelay instead of delay() so the FreeRTOS scheduler keeps running
  // and the watchdog timer gets fed during USB enumeration.
  Serial.printf("[HIDMouse] Waiting %d ms for USB enumeration (yielding)...\n", Config::USB_READY_DELAY_MS);
  vTaskDelay(pdMS_TO_TICKS(Config::USB_READY_DELAY_MS));
  _ready = true;
  Serial.println("[HIDMouse] Ready.");
}

bool HIDMouseManager::isReady() const {
  return _ready;
}

void HIDMouseManager::moveLarge(int totalDx, int totalDy) {
  if (!_ready) {
    Serial.println("[HIDMouse] moveLarge called but not ready — ignoring.");
    return;
  }

  Serial.printf("[HIDMouse] moveLarge start: dx=%d dy=%d\n", totalDx, totalDy);
  int steps = 0;

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
    steps++;

    // Feed the watchdog every 10 steps to prevent WDT resets during long moves.
    if (steps % 10 == 0) {
      vTaskDelay(1);
    }

    delay(Config::STEP_DELAY_MS);
  }

  Serial.printf("[HIDMouse] moveLarge complete: %d steps taken.\n", steps);
}

void HIDMouseManager::leftClick() {
  if (!_ready) {
    Serial.println("[HIDMouse] leftClick called but not ready — ignoring.");
    return;
  }
  Serial.println("[HIDMouse] leftClick.");
  _mouse.click(MOUSE_LEFT);
}
