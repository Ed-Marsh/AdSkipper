B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\..\Files&FilesSync=True
#End Region

#Macro: Title, Export B4XPages, ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip

Sub Class_Globals
    Private Const TAG As String = "[MainPage]"

    Private Root    As B4XView
    Private xui     As XUI

    ' ── BLE ──────────────────────────────────────────────────────────────────
    Private Ble         As BleManager
    Private mScanning   As Boolean

    ' ── Device name to match during scan (must match Config.h BLE_DEVICE_NAME)
    Private Const ESP32_NAME As String = "ESP32-HID-Controller"

    ' ── Command bytes (must match Config.h) ───────────────────────────────────
    Private Const CMD_MACRO1 As Byte = 0x01
    Private Const CMD_MACRO2 As Byte = 0x02
    Private Const CMD_MACRO3 As Byte = 0x03

    ' ── Default offsets if nothing saved yet ──────────────────────────────────
    Private Const DEFAULT_OFFSET_X As Int = 160
    Private Const DEFAULT_OFFSET_Y As Int = 70

    ' ── KVS key prefix (must match MacroSetupPage) ────────────────────────────
    Private Const KVS_KEY_X As String = "macro_offset_x_"
    Private Const KVS_KEY_Y As String = "macro_offset_y_"

    ' ── Layout views ──────────────────────────────────────────────────────────
    Private lblConnectOrDisconnect  As B4XView
    Private lblSendMacro1           As B4XView
    Private lblSendMacro2           As B4XView
    Private lblSendMacro3           As B4XView
End Sub

Public Sub Initialize
    Log(TAG & " Initialize called.")
End Sub

Private Sub B4XPage_Created(Root1 As B4XView)
    Log(TAG & " B4XPage_Created called.")
    Root = Root1
    Root.LoadLayout("MainPage")
    Ble.Initialize("Ble", Me)
    Log(TAG & " Ready.")
End Sub

' ── Connect / Disconnect ──────────────────────────────────────────────────────

Private Sub lblConnectOrDisconnect_Click
    Log(TAG & " lblConnectOrDisconnect called. Connected=" & Ble.IsConnected & " Scanning=" & mScanning)
    If Ble.IsConnected Then
        Ble.Disconnect
    Else If mScanning Then
        Ble.StopScan
        mScanning = False
        Log(TAG & " Scan cancelled by user.")
    Else
        Log(TAG & " Requesting BLE permissions...")
        RequestBlePermissions
    End If
End Sub

Private Sub RequestBlePermissions
    Log(TAG & " RequestBlePermissions called.")
    Dim rp As RuntimePermissions
    Dim phone As Phone
    Dim Permissions As List
    If phone.SdkVersion >= 31 Then
        Log(TAG & " Android 12+ — requesting BLUETOOTH_SCAN, BLUETOOTH_CONNECT.")
        Permissions = Array("android.permission.BLUETOOTH_SCAN", _
                            "android.permission.BLUETOOTH_CONNECT")
    Else
        Log(TAG & " Android <12 — requesting ACCESS_FINE_LOCATION.")
        Permissions = Array(rp.PERMISSION_ACCESS_FINE_LOCATION)
    End If
    For Each perm As String In Permissions
        Log(TAG & " Checking permission: " & perm)
        If rp.Check(perm) Then
            Log(TAG & " Already granted: " & perm)
        Else
            rp.CheckAndRequest(perm)
            Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
            Log(TAG & " Permission result: " & Permission & " = " & Result)
            If Result = False Then
                Log(TAG & " Permission denied: " & perm)
                ToastMessageShow("Permission denied: " & perm, True)
                Return
            End If
        End If
    Next
    Log(TAG & " All permissions granted — starting scan.")
    mScanning = True
    Ble.StartScan
End Sub

' ── Macro buttons — Click sends macro, LongClick opens setup ──────────────────

Private Sub lblSendMacro1_Click
    Log(TAG & " lblSendMacro1 click.")
    SendMacro(1, CMD_MACRO1)
End Sub

Private Sub lblSendMacro1_LongClick
    Log(TAG & " lblSendMacro1 long click — opening setup.")
    OpenMacroSetup(1)
End Sub

Private Sub lblSendMacro2_Click
    Log(TAG & " lblSendMacro2 click.")
    SendMacro(2, CMD_MACRO2)
End Sub

Private Sub lblSendMacro2_LongClick
    Log(TAG & " lblSendMacro2 long click — opening setup.")
    OpenMacroSetup(2)
End Sub

Private Sub lblSendMacro3_Click
    Log(TAG & " lblSendMacro3 click.")
    SendMacro(3, CMD_MACRO3)
End Sub

Private Sub lblSendMacro3_LongClick
    Log(TAG & " lblSendMacro3 long click — opening setup.")
    OpenMacroSetup(3)
End Sub

' ── Helpers ───────────────────────────────────────────────────────────────────

Private Sub SendMacro(MacroNum As Int, Cmd As Byte)
    If Not(Ble.IsConnected) Then
        ToastMessageShow("Not connected to ESP32.", True)
        Return
    End If
    ' Load saved offsets for this macro.
    Dim kvs As KeyValueStore
    kvs.Initialize(xui.DefaultFolder, "AdSkipperKVS")
    Dim offsetX As Int = kvs.GetDefault(KVS_KEY_X & MacroNum, DEFAULT_OFFSET_X)
    Dim offsetY As Int = kvs.GetDefault(KVS_KEY_Y & MacroNum, DEFAULT_OFFSET_Y)
    Log(TAG & " SendMacro " & MacroNum & ": cmd=0x" & Bit.ToHexString(Cmd) & " X=" & offsetX & " Y=" & offsetY)

    ' Build 5-byte packet: [cmd, x_high, x_low, y_high, y_low]
    Dim data(5) As Byte
    data(0) = Cmd
    data(1) = Bit.And(Bit.ShiftRight(offsetX, 8), 0xFF)
    data(2) = Bit.And(offsetX, 0xFF)
    data(3) = Bit.And(Bit.ShiftRight(offsetY, 8), 0xFF)
    data(4) = Bit.And(offsetY, 0xFF)
    Ble.SendBytes(data)
    ToastMessageShow("Macro " & MacroNum & " sent.", False)
End Sub

Private Sub OpenMacroSetup(MacroNum As Int)
    If Not(Ble.IsConnected) Then
        ToastMessageShow("Connect to ESP32 first.", True)
        Return
    End If
    Log(TAG & " Opening MacroSetupPage for macro " & MacroNum)
    Dim setupPage As MacroSetupPage
    B4XPages.ShowPage("MacroSetupPage", setupPage)
    setupPage.Setup(MacroNum, Ble)
End Sub

' ── BLE events ────────────────────────────────────────────────────────────────

Private Sub Ble_DeviceFound(Name As String, DeviceID As String)
    Log(TAG & " Ble_DeviceFound: Name='" & Name & "' ID=" & DeviceID)
    If Name = ESP32_NAME Then
        Log(TAG & " Target device found! Stopping scan and connecting...")
        Ble.StopScan
        mScanning = False
        Ble.Connect(DeviceID)
    Else
        Log(TAG & " Ignoring device: " & Name)
    End If
End Sub

Private Sub Ble_Connected
    Log(TAG & " Ble_Connected — ready to send commands.")
    ToastMessageShow("Connected to ESP32.", False)
End Sub

Private Sub Ble_Disconnected
    Log(TAG & " Ble_Disconnected.")
    ToastMessageShow("Disconnected.", True)
End Sub

Private Sub Ble_Error(Message As String)
    Log(TAG & " Ble_Error: " & Message)
    ToastMessageShow("BLE error: " & Message, True)
    mScanning = False
End Sub
