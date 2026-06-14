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
    Private Const TAG As String = "[BleManager]"

    ' ── BLE UUIDs — must match Config.h on the ESP32 ─────────────────────────
    Private Const SERVICE_UUID      As String = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
    Private Const COMMAND_CHAR_UUID As String = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

    Private mManager        As BleManager2
    Private mEventName      As String
    Private mConnected      As Boolean
    Private mBluetoothReady As Boolean
    Private mPage           As Object  ' reference to the calling B4XPage
End Sub

Public Sub Initialize(EventName As String, Page As Object)
    Log(TAG & " Initialize, EventName=" & EventName)
    mEventName      = EventName
    mConnected      = False
    mBluetoothReady = False
    mPage           = Page
    mManager.Initialize("Ble_Inner")
    Log(TAG & " BleManager2 initialized.")
End Sub

' ── Scanning ──────────────────────────────────────────────────────────────────

Public Sub StartScan
    Log(TAG & " StartScan called. BluetoothReady=" & mBluetoothReady)
    If Not(mBluetoothReady) Then
        RaiseEvent_Error("Bluetooth is not enabled.")
        Return
    End If
    Log(TAG & " Starting Scan2...")
    mManager.Scan2(Null, False)
End Sub

Public Sub StopScan
    Log(TAG & " StopScan called.")
    mManager.StopScan
End Sub

' ── Connection ────────────────────────────────────────────────────────────────

Public Sub Connect(DeviceID As String)
    Log(TAG & " Connect called. DeviceID=" & DeviceID)
    mManager.Connect2(DeviceID, False)
End Sub

Public Sub Disconnect
    Log(TAG & " Disconnect called. Connected=" & mConnected)
    If mConnected Then
        mManager.Disconnect
    End If
End Sub

Public Sub IsConnected As Boolean
    Return mConnected
End Sub

' ── Commands ──────────────────────────────────────────────────────────────────

Public Sub SendCommand(Command As Byte)
    Log(TAG & " SendCommand called. Command=0x" & Bit.ToHexString(Command) & " Connected=" & mConnected)
    If Not(mConnected) Then
        RaiseEvent_Error("Not connected to ESP32.")
        Return
    End If
    Dim data(1) As Byte
    data(0) = Command
    Log(TAG & " Writing data to characteristic...")
    mManager.WriteData(SERVICE_UUID, COMMAND_CHAR_UUID, data)
End Sub

' ── BleManager2 inner callbacks ───────────────────────────────────────────────

Private Sub Ble_Inner_StateChanged(State As Int)
    mBluetoothReady = (State = mManager.STATE_POWERED_ON)
    Log(TAG & " StateChanged: State=" & State & " BluetoothReady=" & mBluetoothReady)
End Sub

Private Sub Ble_Inner_DeviceFound(Name As String, ID As String, AdvertisingData As Map, RSSI As Double)
    Log(TAG & " DeviceFound: Name='" & Name & "' ID=" & ID & " RSSI=" & RSSI)
    CallSub3(mPage, mEventName & "_DeviceFound", Name, ID)
End Sub

Private Sub Ble_Inner_Connected(Services As List)
    Log(TAG & " Connected callback fired. Services found: " & Services.Size)
    Dim found As Boolean = False
    For Each svc As String In Services
        Log(TAG & "   Service UUID: " & svc)
        If svc.ToLowerCase = SERVICE_UUID.ToLowerCase Then
            found = True
        End If
    Next
    If found Then
        Log(TAG & " Target service found — marking as connected.")
        mConnected = True
        CallSub(mPage, mEventName & "_Connected")
    Else
        Log(TAG & " ERROR: Target service NOT found after connecting.")
        RaiseEvent_Error("ESP32 AdSkipper GATT service not found.")
        mManager.Disconnect
    End If
End Sub

Private Sub Ble_Inner_Disconnected
    Log(TAG & " Disconnected callback fired.")
    mConnected = False
    CallSub(mPage, mEventName & "_Disconnected")
End Sub

Private Sub Ble_Inner_DataAvailable(ServiceID As String, CharacteristicID As String, Data() As Byte)
    Log(TAG & " DataAvailable (unexpected): ServiceID=" & ServiceID & " CharID=" & CharacteristicID)
End Sub

Private Sub Ble_Inner_WriteComplete(ServiceID As String, CharacteristicID As String)
    Log(TAG & " WriteComplete: ServiceID=" & ServiceID & " CharID=" & CharacteristicID)
End Sub

' ── Helpers ───────────────────────────────────────────────────────────────────

Private Sub RaiseEvent_Error(Message As String)
    Log(TAG & " ERROR: " & Message)
    CallSub2(mPage, mEventName & "_Error", Message)
End Sub
