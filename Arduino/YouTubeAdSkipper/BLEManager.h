#pragma once

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

class MacroManager; // forward declaration avoids circular include

/**
 * BLEManager
 * Owns the BLE GATT server.  Exposes one writable characteristic;
 * when the Android app writes a command byte the value is forwarded
 * to MacroManager::executeMacro().
 *
 * Architecture note:
 *   The ESP32 BLE library requires callback objects derived from
 *   BLEServerCallbacks / BLECharacteristicCallbacks.  Rather than
 *   making those classes friends or using inheritance, we store a
 *   static BLEManager* (s_instance) so the callback objects can
 *   delegate back to the manager's private methods.  This keeps
 *   BLEManager self-contained without exposing internals.
 */
class BLEManager {
public:
  explicit BLEManager(MacroManager& macroManager);

  // Initialise BLE stack, create GATT server, and start advertising.
  void begin();

  // Call from loop() to restart advertising after a client disconnects.
  void update();

  bool isConnected() const;

  // Called by the static callback shim — do not call directly.
  void onClientConnect();
  void onClientDisconnect();
  void onCommandWritten(BLECharacteristic* characteristic);

private:
  MacroManager& _macroManager;
  BLEServer*    _server;
  bool          _connected;
  bool          _needsAdvertisingRestart;

  void startAdvertising();
};
