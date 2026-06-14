B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
'BleManager
'Wraps BleManager2 to handle scanning, connecting and writing to the ESP32 AdSkipper.
'
'Events raised (prefix passed to Initialize):
'  _DeviceFound (Name As String, DeviceID As String)
'  _Connected
'  _Disconnected
'  _Error (Message As String)

Sub Class_Globals
    ' ── BLE UUIDs — must match Config.h on the ESP32 ─────────────────────────
    Private Const SERVICE_UUID      As String = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
    Private Const COMMAND_CHAR_UUID As String = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

    Private mManager    As BleManager2
    Private mEventName  As String
    Private mConnected  As Boolean
    Private mDeviceID   As String   ' ID of the connected/connecting device
End Sub

Public Sub Initialize(EventName As String)
    mEventName  = EventName
    mConnected  = False
    mDeviceID   = ""
    mManager.Initialize("Ble_Inner")
End Sub

' ── Scanning ──────────────────────────────────────────────────────────────────

Public Sub StartScan
    If mManager.IsEnabled = False Then
        RaiseEvent_Error("Bluetooth is not enabled.")
        Return
    End If
    ' Scan without UUID filter — filter by name in DeviceFound instead,
    ' because some Android versions suppress UUID-filtered results.
    mManager.Scan2(Null, False)
End Sub

Public Sub StopScan
    mManager.StopScan
End Sub

' ── Connection ────────────────────────────────────────────────────────────────

Public Sub Connect(DeviceID As String)
    mDeviceID = DeviceID
    mManager.Connect2(DeviceID, False)
End Sub

Public Sub Disconnect
    If mConnected Then
        mManager.Disconnect
    End If
End Sub

Public Sub IsConnected As Boolean
    Return mConnected
End Sub

' ── Commands ──────────────────────────────────────────────────────────────────

' Send a single macro command byte (0x01, 0x02 or 0x03) to the ESP32.
Public Sub SendCommand(Command As Byte)
    If Not(mConnected) Then
        RaiseEvent_Error("Not connected to ESP32.")
        Return
    End If
    Dim data(1) As Byte
    data(0) = Command
    mManager.WriteData(SERVICE_UUID, COMMAND_CHAR_UUID, data)
End Sub

' ── BleManager2 inner callbacks ───────────────────────────────────────────────

Private Sub Ble_Inner_DeviceFound(Name As String, ID As String, AdvertisingData As Map, RSSI As Double)
    ' Relay every discovered device back to the page — it will filter by name.
    CallSubDelayed3(B4XPages.GetManager, mEventName & "_DeviceFound", Name, ID)
End Sub

Private Sub Ble_Inner_Connected(Services As Map)
    If Services.ContainsKey(SERVICE_UUID) Then
        mConnected = True
        CallSubDelayed(B4XPages.GetManager, mEventName & "_Connected")
    Else
        ' Connected to the right device but our service wasn't found.
        RaiseEvent_Error("ESP32 AdSkipper GATT service not found.")
        mManager.Disconnect
    End If
End Sub

Private Sub Ble_Inner_Disconnected
    mConnected = False
    mDeviceID  = ""
    CallSubDelayed(B4XPages.GetManager, mEventName & "_Disconnected")
End Sub

Private Sub Ble_Inner_DataAvailable(ServiceID As String, CharacteristicID As String, Data() As Byte)
    ' Command characteristic is write-only; nothing expected here.
End Sub

Private Sub Ble_Inner_WriteComplete(ServiceID As String, CharacteristicID As String, Status As Int)
    If Status <> 0 Then
        RaiseEvent_Error("Write failed, status: " & Status)
    End If
End Sub

' ── Helpers ───────────────────────────────────────────────────────────────────

Private Sub RaiseEvent_Error(Message As String)
    Log("BleManager Error: " & Message)
    CallSubDelayed2(B4XPages.GetManager, mEventName & "_Error", Message)
End Sub
