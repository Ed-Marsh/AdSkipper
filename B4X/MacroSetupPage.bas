B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
'MacroSetupPage
'Opened via long press on a macro button in MainPage.
'Allows the user to jog the mouse from the bottom-right corner to the desired
'click position, then save those offsets for the macro.
'
'Views required in "MacroSetupLayout":
'  lblTitle         - shows which macro is being configured
'  lblOffsetX       - shows current X offset (pixels left from corner)
'  lblOffsetY       - shows current Y offset (pixels up from corner)
'  edtStepSize      - EditText, default "10", defines nudge step in pixels
'  btnUp            - nudge mouse up
'  btnDown          - nudge mouse down
'  btnLeft          - nudge mouse left
'  btnRight         - nudge mouse right
'  btnSave          - save offsets and close
'  btnCancel        - discard and close

Sub Class_Globals
    Private Const TAG As String = "[MacroSetupPage]"

    ' ── Command bytes — must match Config.h ───────────────────────────────────
    Private Const CMD_GOTO_CORNER   As Byte = 0x10
    Private Const CMD_RELATIVE_MOVE As Byte = 0x11

    ' ── KVS key prefix ────────────────────────────────────────────────────────
    Private Const KVS_KEY_X As String = "macro_offset_x_"
    Private Const KVS_KEY_Y As String = "macro_offset_y_"

    ' ── Default offsets (used if no saved value exists) ───────────────────────
    Private Const DEFAULT_OFFSET_X As Int = 160
    Private Const DEFAULT_OFFSET_Y As Int = 70

    Private Root        As B4XView
    Private xui         As XUI

    ' ── UI views ──────────────────────────────────────────────────────────────
    Private lblTitle    As B4XView
    Private lblOffsetX  As B4XView
    Private lblOffsetY  As B4XView
    Private edtStepSize As B4XView
    Private btnUp       As B4XView
    Private btnDown     As B4XView
    Private btnLeft     As B4XView
    Private btnRight    As B4XView
    Private btnSave     As B4XView
    Private btnCancel   As B4XView

    ' ── State ─────────────────────────────────────────────────────────────────
    Private mMacroNum   As Int      ' 1, 2 or 3
    Private mOffsetX    As Int      ' pixels LEFT from bottom-right corner
    Private mOffsetY    As Int      ' pixels UP from bottom-right corner
    Private mBle        As BleManager  ' shared BLE instance passed from MainPage
End Sub

Public Sub Initialize
    Log(TAG & " Initialize called.")
End Sub

Private Sub B4XPage_Created(Root1 As B4XView)
    Log(TAG & " B4XPage_Created.")
    Root = Root1
    Root.LoadLayout("MacroSetupLayout")
End Sub

' Called by MainPage before ShowPage — stores params only, no UI access yet.
Public Sub Setup(MacroNum As Int, Ble As BleManager)
    Log(TAG & " Setup: MacroNum=" & MacroNum)
    mMacroNum = MacroNum
    mBle      = Ble

    ' Load saved offsets, or use defaults.
    Dim kvs As KeyValueStore
    kvs.Initialize(xui.DefaultFolder, "AdSkipperKVS")
    mOffsetX = kvs.GetDefault(KVS_KEY_X & MacroNum, DEFAULT_OFFSET_X)
    mOffsetY = kvs.GetDefault(KVS_KEY_Y & MacroNum, DEFAULT_OFFSET_Y)
    Log(TAG & " Loaded offsets: X=" & mOffsetX & " Y=" & mOffsetY)
End Sub

' Layout is loaded and views are ready — update UI and send mouse to corner.
Private Sub B4XPage_Appear
    Log(TAG & " B4XPage_Appear.")
    lblTitle.Text = "Configure Macro " & mMacroNum
    UpdateOffsetLabels
    GotoCorner
End Sub

' ── Nudge buttons ─────────────────────────────────────────────────────────────

Private Sub btnUp_Click
    Nudge(0, -StepSize)   ' UP = negative dy = decrease Y offset
End Sub

Private Sub btnDown_Click
    Nudge(0, StepSize)
End Sub

Private Sub btnLeft_Click
    Nudge(-StepSize, 0)   ' LEFT = negative dx = decrease X offset
End Sub

Private Sub btnRight_Click
    Nudge(StepSize, 0)
End Sub

Private Sub Nudge(dx As Int, dy As Int)
    Log(TAG & " Nudge dx=" & dx & " dy=" & dy)
    ' The offsets represent how far LEFT and UP the target is from the corner.
    ' Moving left (negative dx) increases the left offset.
    ' Moving up (negative dy) increases the up offset.
    mOffsetX = mOffsetX - dx
    mOffsetY = mOffsetY - dy
    UpdateOffsetLabels
    SendRelativeMove(dx, dy)
End Sub

' ── Save / Cancel ─────────────────────────────────────────────────────────────

Private Sub btnSave_Click
    Log(TAG & " Save: MacroNum=" & mMacroNum & " X=" & mOffsetX & " Y=" & mOffsetY)
    Dim kvs As KeyValueStore
    kvs.Initialize(xui.DefaultFolder, "AdSkipperKVS")
    kvs.Put(KVS_KEY_X & mMacroNum, mOffsetX)
    kvs.Put(KVS_KEY_Y & mMacroNum, mOffsetY)
    ToastMessageShow("Macro " & mMacroNum & " saved.", False)
    B4XPages.ClosePage(Me)
End Sub

Private Sub btnCancel_Click
    Log(TAG & " Cancel.")
    B4XPages.ClosePage(Me)
End Sub

' ── BLE helpers ───────────────────────────────────────────────────────────────

Private Sub GotoCorner
    Log(TAG & " Sending CMD_GOTO_CORNER.")
    Dim data(1) As Byte
    data(0) = CMD_GOTO_CORNER
    mBle.SendBytes(data)
End Sub

Private Sub SendRelativeMove(dx As Int, dy As Int)
    Dim data(5) As Byte
    data(0) = CMD_RELATIVE_MOVE
    ' Encode dx as signed int16 big-endian.
    data(1) = Bit.And(Bit.ShiftRight(dx, 8), 0xFF)
    data(2) = Bit.And(dx, 0xFF)
    ' Encode dy as signed int16 big-endian.
    data(3) = Bit.And(Bit.ShiftRight(dy, 8), 0xFF)
    data(4) = Bit.And(dy, 0xFF)
    Log(TAG & " SendRelativeMove dx=" & dx & " dy=" & dy)
    mBle.SendBytes(data)
End Sub

' ── Helpers ───────────────────────────────────────────────────────────────────

Private Sub StepSize As Int
    Dim s As String = edtStepSize.Text
    If s = "" Then Return 10
    Dim n As Int = s
    If n <= 0 Then Return 10
    Return n
End Sub

Private Sub UpdateOffsetLabels
    lblOffsetX.Text = "X (left from corner): " & mOffsetX
    lblOffsetY.Text = "Y (up from corner): " & mOffsetY
End Sub
