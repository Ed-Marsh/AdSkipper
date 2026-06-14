B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
'BleManager
'Handles BLE scanning, connection and characteristic writes to the ESP32 AdSkipper.
'
'Usage:
'  1. Call Initialize passing in a handler Sub name prefix (e.g. "Ble") and the calling module.
'  2. Call StartScan to find the ESP32. The event BleManager_DeviceFound fires for each result.
'  3. Call Connect(device) when the right device is found.
'  4. The event BleManager_Connected fires when the GATT service and characteristic are ready.
'  5. Call SendCommand(byte) to trigger a macro on the ESP32.
'  6. Call Disconnect when done.
'
'Events raised (use the prefix passed to Initialize):
'  _DeviceFound (Name As String, Device As BleDevice)
'  _Connected
'  _Disconnected
'  _Error (Message As String)

Sub Class_Globals
    ' ── BLE UUIDs — must match Config.h on the ESP32 ─────────────────────────
    Private Const SERVICE_UUID      As String = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
    Private Const COMMAND_CHAR_UUID As String = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

    Private mBle        As BleManager2
    Private mGatt       As BleGatt
    Private mEventName  As String   ' prefix for raised events
    Private mConnected  As Boolean
End Sub

Public Sub Initialize(EventName As String)
    mEventName = EventName
    mConnected = False
    mBle.Initialize("Ble_Scanner")
End Sub

' ── Scanning ─────────────────────────────────────────────────────────────────

Public Sub StartScan
    If mBle.IsEnabled = False Then
        RaiseEvent_Error("Bluetooth is not enabled on this device.")
        Return
    End If
    mBle.ScanPeriod = 10000 ' 10 seconds
    mBle.Scan(Array As String(SERVICE_UUID)) ' filter by our service UUID
End Sub

Public Sub StopScan
    mBle.StopScan
End Sub

' ── Connection ───────────────────────────────────────────────────────────────

Public Sub Connect(Device As BleDevice)
    mGatt.Initialize("Ble_Gatt", Device, False)
    mGatt.Connect
End Sub

Public Sub Disconnect
    If mConnected Then
        mGatt.Disconnect
    End If
End Sub

Public Sub IsConnected As Boolean
    Return mConnected
End Sub

' ── Commands ─────────────────────────────────────────────────────────────────

' Send a single command byte to the ESP32 (0x01, 0x02, or 0x03 for macros 1-3).
Public Sub SendCommand(Command As Byte)
    If Not(mConnected) Then
        RaiseEvent_Error("Not connected to ESP32.")
        Return
    End If
    Dim data(1) As Byte
    data(0) = Command
    mGatt.WriteData(SERVICE_UUID, COMMAND_CHAR_UUID, data)
End Sub

' ── BleManager2 scanner callbacks ────────────────────────────────────────────

Private Sub Ble_Scanner_DeviceFound(Name As String, ID As String, AdvertisingData As Map, RSSI As Double)
    ' Surface every discovered device to the caller so they can identify the ESP32.
    Dim device As BleDevice
    device = mBle.GetDevice(ID)
    CallSubDelayed3(B4XPages.GetManager, mEventName & "_DeviceFound", Name, device)
End Sub

Private Sub Ble_Scanner_ScanComplete
    ' Scan period elapsed — caller can decide whether to retry.
    Log("BleManager: Scan complete.")
End Sub

' ── BleGatt callbacks ────────────────────────────────────────────────────────

Private Sub Ble_Gatt_Connected
    ' Discover services before we declare ourselves connected.
    mGatt.DiscoverServices
End Sub

Private Sub Ble_Gatt_Disconnected
    mConnected = False
    CallSubDelayed(B4XPages.GetManager, mEventName & "_Disconnected")
End Sub

Private Sub Ble_Gatt_ServicesDiscovered(Services As Map)
    If Services.ContainsKey(SERVICE_UUID) Then
        mConnected = True
        CallSubDelayed(B4XPages.GetManager, mEventName & "_Connected")
    Else
        RaiseEvent_Error("ESP32 AdSkipper service not found after connecting.")
        mGatt.Disconnect
    End If
End Sub

Private Sub Ble_Gatt_DataAvailable(ServiceID As String, CharacteristicID As String, Data() As Byte)
    ' Command characteristic is write-only; we don't expect data back.
End Sub

Private Sub Ble_Gatt_WriteComplete(ServiceID As String, CharacteristicID As String)
    Log("BleManager: Write complete.")
End Sub

' ── Helpers ──────────────────────────────────────────────────────────────────

Private Sub RaiseEvent_Error(Message As String)
    Log("BleManager Error: " & Message)
    CallSubDelayed2(B4XPages.GetManager, mEventName & "_Error", Message)
End Sub
