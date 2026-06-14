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

    ' ── Command bytes (must match MacroManager.cpp case values) ───────────────
    Private Const CMD_MACRO1 As Byte = 0x01
    Private Const CMD_MACRO2 As Byte = 0x02
    Private Const CMD_MACRO3 As Byte = 0x03
	Private lblConnectOrDisconnect As B4XView
	Private lblSendMacro1 As B4XView
	Private lblSendMacro2 As B4XView
	Private lblSendMacro3 As B4XView
End Sub

Public Sub Initialize
    Log(TAG & " Initialize called.")
End Sub

Private Sub B4XPage_Created(Root1 As B4XView)
    Log(TAG & " B4XPage_Created called.")
    Root = Root1
    Root.LoadLayout("MainPage")
    Ble.Initialize("Ble")
    Log(TAG & " Ready.")
End Sub

' ── Connect / Disconnect ──────────────────────────────────────────────────────


Private Sub RequestBlePermissions
    Log(TAG & " RequestBlePermissions called.")
    Dim rp As RuntimePermissions
    Dim phone As Phone
    Dim Permissions As List
    If phone.SdkVersion >= 31 Then
        Log(TAG & " Android 12+ — requesting BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION.")
        Permissions = Array("android.permission.BLUETOOTH_SCAN", _
                            "android.permission.BLUETOOTH_CONNECT", _
                            rp.PERMISSION_ACCESS_FINE_LOCATION)
    Else
        Log(TAG & " Android <12 — requesting ACCESS_FINE_LOCATION only.")
        Permissions = Array(rp.PERMISSION_ACCESS_FINE_LOCATION)
    End If
    For Each perm As String In Permissions
        Log(TAG & " Requesting permission: " & perm)
        rp.CheckAndRequest(perm)
        Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
        Log(TAG & " Permission result: " & Permission & " = " & Result)
        If Result = False Then
            ToastMessageShow("Permission denied: " & Permission, True)
            Return
        End If
    Next
    Log(TAG & " All permissions granted — starting scan.")
    mScanning = True
    Ble.StartScan
End Sub

' ── BLE events (raised by BleManager class) ───────────────────────────────────

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


Private Sub lblSendMacro3_Click
	Log(TAG & " lblSendMacro3 called.")
	Ble.SendCommand(CMD_MACRO3)
	ToastMessageShow("Macro 3 sent.", False)
End Sub

Private Sub lblSendMacro2_Click
	Log(TAG & " lblSendMacro2 called.")
	Ble.SendCommand(CMD_MACRO2)
	ToastMessageShow("Macro 2 sent.", False)
End Sub

Private Sub lblSendMacro1_Click
	Log(TAG & " lblSendMacro1 called.")
	Ble.SendCommand(CMD_MACRO1)
	ToastMessageShow("Macro 1 sent.", False)
End Sub

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