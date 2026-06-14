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
    Private Root    As B4XView
    Private xui     As XUI

    ' ── UI views (matched to layout) ─────────────────────────────────────────
    Private lblStatus   As B4XView
    Private btnConnect  As B4XView
    Private btnMacro1   As B4XView
    Private btnMacro2   As B4XView
    Private btnMacro3   As B4XView

    ' ── BLE ──────────────────────────────────────────────────────────────────
    Private Ble         As BleManager   ' our wrapper class
    Private mScanning   As Boolean
    Private mFoundDevice As BleDevice
    Private mHaveDevice As Boolean

    ' ── ESP32 device name to match during scan ────────────────────────────────
    Private Const ESP32_NAME As String = "ESP32-HID-Controller"

    ' ── Command bytes (must match MacroManager.cpp case values) ───────────────
    Private Const CMD_MACRO1 As Byte = 0x01
    Private Const CMD_MACRO2 As Byte = 0x02
    Private Const CMD_MACRO3 As Byte = 0x03
End Sub

Public Sub Initialize
    ' B4XPages calls this once before the page is created.
End Sub

Private Sub B4XPage_Created(Root1 As B4XView)
    Root = Root1
    Root.LoadLayout("MainPage")

    ' Initialise BLE manager — events come back with prefix "Ble"
    Ble.Initialize("Ble")

    SetStatus("Ready — tap Connect to find ESP32.")
    SetMacroButtonsEnabled(False)
End Sub

' ── Connect button ────────────────────────────────────────────────────────────

Private Sub btnConnect_Click
    If Ble.IsConnected Then
        ' Already connected — disconnect.
        Ble.Disconnect
        btnConnect.SetText("Connect")
        SetStatus("Disconnecting...")
    Else If mScanning Then
        ' Cancel scan.
        Ble.StopScan
        mScanning = False
        btnConnect.SetText("Connect")
        SetStatus("Scan cancelled.")
    Else
        ' Start scan.
        mHaveDevice = False
        mScanning = True
        btnConnect.SetText("Cancel")
        SetStatus("Scanning for " & ESP32_NAME & "...")
        Ble.StartScan
    End If
End Sub

' ── Macro buttons ─────────────────────────────────────────────────────────────

Private Sub btnMacro1_Click
    SendMacro(CMD_MACRO1, "Macro 1")
End Sub

Private Sub btnMacro2_Click
    SendMacro(CMD_MACRO2, "Macro 2")
End Sub

Private Sub btnMacro3_Click
    SendMacro(CMD_MACRO3, "Macro 3")
End Sub

Private Sub SendMacro(Command As Byte, Label As String)
    If Not(Ble.IsConnected) Then
        xui.ToastMessageShow("Not connected to ESP32.", True)
        Return
    End If
    Ble.SendCommand(Command)
    xui.ToastMessageShow(Label & " sent.", False)
End Sub

' ── BLE events ───────────────────────────────────────────────────────────────

' Called for each device found during scan.
Private Sub Ble_DeviceFound(Name As String, Device As BleDevice)
    If Name = ESP32_NAME Then
        ' Found our device — stop scanning and connect.
        Ble.StopScan
        mScanning = False
        mFoundDevice = Device
        mHaveDevice = True
        SetStatus("Found " & ESP32_NAME & " — connecting...")
        Ble.Connect(Device)
    End If
End Sub

' Called once GATT services are discovered and the device is ready.
Private Sub Ble_Connected
    btnConnect.SetText("Disconnect")
    SetStatus("Connected to " & ESP32_NAME)
    SetMacroButtonsEnabled(True)
    xui.ToastMessageShow("Connected to ESP32.", False)
End Sub

Private Sub Ble_Disconnected
    btnConnect.SetText("Connect")
    SetStatus("Disconnected.")
    SetMacroButtonsEnabled(False)
    xui.ToastMessageShow("Disconnected from ESP32.", True)
End Sub

Private Sub Ble_Error(Message As String)
    SetStatus("Error: " & Message)
    xui.ToastMessageShow("BLE error: " & Message, True)
    mScanning = False
    btnConnect.SetText("Connect")
    SetMacroButtonsEnabled(False)
End Sub

' ── Helpers ───────────────────────────────────────────────────────────────────

Private Sub SetStatus(Text As String)
    lblStatus.SetText(Text)
End Sub

Private Sub SetMacroButtonsEnabled(Enabled As Boolean)
    btnMacro1.Enabled = Enabled
    btnMacro2.Enabled = Enabled
    btnMacro3.Enabled = Enabled
End Sub
