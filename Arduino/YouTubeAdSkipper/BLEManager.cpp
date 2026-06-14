#include "BLEManager.h"
#include "MacroManager.h"
#include "Config.h"

// ── Static shim ───────────────────────────────────────────────────────────────
// The ESP32 BLE callback classes can't hold a reference to BLEManager, so we
// use a module-local pointer that is set once during BLEManager::begin().

static BLEManager* s_instance = nullptr;

// ── Callback classes ──────────────────────────────────────────────────────────

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* /*server*/) override {
    if (s_instance) s_instance->onClientConnect();
  }
  void onDisconnect(BLEServer* /*server*/) override {
    if (s_instance) s_instance->onClientDisconnect();
  }
};

class CommandCharCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* characteristic) override {
    if (s_instance) s_instance->onCommandWritten(characteristic);
  }
};

// ── BLEManager ────────────────────────────────────────────────────────────────

BLEManager::BLEManager(MacroManager& macroManager)
  : _macroManager(macroManager),
    _server(nullptr),
    _connected(false),
    _needsAdvertisingRestart(false) {}

void BLEManager::begin() {
  s_instance = this;

  BLEDevice::init(Config::BLE_DEVICE_NAME);

  _server = BLEDevice::createServer();
  _server->setCallbacks(new ServerCallbacks());

  // Create custom GATT service.
  BLEService* service = _server->createService(Config::SERVICE_UUID);

  // Command characteristic: WRITE only (no notify, no read needed).
  BLECharacteristic* commandChar = service->createCharacteristic(
    Config::COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  commandChar->setCallbacks(new CommandCharCallbacks());

  service->start();
  startAdvertising();

  Serial.printf("[BLEManager] Advertising as \"%s\"\n", Config::BLE_DEVICE_NAME);
}

void BLEManager::update() {
  // After a client disconnects the server must explicitly restart advertising.
  if (_needsAdvertisingRestart) {
    _needsAdvertisingRestart = false;
    startAdvertising();
    Serial.println("[BLEManager] Re-advertising after disconnect.");
  }
}

bool BLEManager::isConnected() const {
  return _connected;
}

// ── Callback implementations ──────────────────────────────────────────────────

void BLEManager::onClientConnect() {
  _connected = true;
  Serial.println("[BLEManager] Client connected.");
}

void BLEManager::onClientDisconnect() {
  _connected = false;
  _needsAdvertisingRestart = true;
  Serial.println("[BLEManager] Client disconnected.");
}

void BLEManager::onCommandWritten(BLECharacteristic* characteristic) {
  if (!_connected) {
    Serial.println("[BLEManager] Write received but not connected — ignoring.");
    return;
  }

  String value = characteristic->getValue();
  if (value.length() == 0) {
    Serial.println("[BLEManager] Empty write — ignoring.");
    return;
  }

  Serial.printf("[BLEManager] Received %d bytes: ", value.length());
  for (int i = 0; i < value.length(); i++) {
    Serial.printf("0x%02X ", (uint8_t)value[i]);
  }
  Serial.println();

  _macroManager.executeCommand(
    reinterpret_cast<const uint8_t*>(value.c_str()),
    value.length()
  );
}

// ── Private helpers ───────────────────────────────────────────────────────────

void BLEManager::startAdvertising() {
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(Config::SERVICE_UUID);
  // Improve iOS/Android discoverability.
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
}
