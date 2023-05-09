; ppsspp_WM.ahk by NABN00B
; Quick tool to retrieve the pointer to and the address in Windows memory where the emulated PSP memory starts from.
; Developed for and tested in AutoHotkey v1.1.31.01 to be run on x86-64 Windows.
; Compile using the "Unicode 64-bit" base file.


; AUTO-EXECUTE
#Warn All, MsgBox
#NoEnv
#SingleInstance Force
SetWinDelay, 0
SetWorkingDir, %A_ScriptDir%

gosub ResetVars
gosub CreateGUI
gosub UpdateGUI
goto MainLogic


MainLogic:
gosub WaitForEmu
gosub GetProcessVars
gosub GetAddresses
gosub UpdateOutput
gosub UpdateGUI
return


ResetVars:
Output := "Waiting for a PPSSPP process to launch..."
ppsspp_WindowClass := "PPSSPPWnd"
ppsspp_ProcessHwnd := 0
ppsspp_ProcessName := ""
ppsspp_Is64BitProcess := 0
Reply0 := Reply1 := Reply2 := Reply3 := 0
psp_MemoryBaseAddress := 0
psp_MemoryBasePointer := 0
ppsspp_ProcessBaseAddress := 0
ppsspp_BaseOffset := 0
return


CreateGUI:
Gui, WindowOutput:New
Gui, WindowOutput:Add, Edit, r13 w336 +WantCtrlA +Multi +ReadOnly vEditOutput
Gui, WindowOutput:Add, Button, w336 gButtonRefresh vButtonRefresh, Refresh
Gui, WindowOutput:Show, AutoSize
return


UpdateGUI:
GuiControl, , EditOutput, %Output%
return


WaitForEmu:
WinWait, ahk_class %ppsspp_WindowClass%
return


GetProcessVars:
WinGet, ppsspp_ProcessHwnd, ID, ahk_class %ppsspp_WindowClass%
WinGet, ppsspp_ProcessName, ProcessName, ahk_class %ppsspp_WindowClass%
if (ppsspp_ProcessName = "PPSSPPWindows64.exe") ; Dirty hack.
	ppsspp_Is64BitProcess := True ; Normally we would retrieve this via ClassMemory.
return


GetAddresses:
gosub SendWMs
if (Reply0 != "FAIL" && Reply1 != "FAIL")
	psp_MemoryBaseAddress := (Reply1 << 32) + Reply0
if (Reply2 != "FAIL" && Reply3 != "FAIL")
	psp_MemoryBasePointer := (Reply3 << 32) + Reply2
ppsspp_ProcessBaseAddress := DllCall("GetWindowLongPtr", "Ptr", ppsspp_ProcessHwnd, "Int", -6, "Int64") ; Normally we would retrieve this via ClassMemory.
if (psp_MemoryBasePointer && ppsspp_ProcessBaseAddress)
	ppsspp_BaseOffset := psp_MemoryBasePointer - ppsspp_ProcessBaseAddress
return


SendWMs:
Reply0 := wm_GetBasePointer(0) ; Retrieve lower 32 bits of PSP Memory Base Address.
Reply2 := wm_GetBasePointer(2) ; Retrieve lower 32 bits of PSP Memory Base Pointer.
if (ppsspp_Is64BitProcess)
{
	Reply1 := wm_GetBasePointer(1) ; Retrieve upper 32 bits of PSP Memory Base Address.
	Reply3 := wm_GetBasePointer(3) ; Retrieve upper 32 bits of PSP Memory Base Pointer.
}
return


wm_GetBasePointer(lParam)
{
	global
	SendMessage, 0xB118, 0, %lParam%, , ahk_id %ppsspp_ProcessHwnd%
	return ErrorLevel
}


UpdateOutput:
Output := Format("Window Class: {:s}`n"
	. "Process hWnd: {:08X}`n"
	. "Process Name: {:s}`n"
	. "Is 64-Bit Process: {:d}`n"
	. "(address) Lower 32 bits: {:08X}`n"
	. "(address) Upper 32 bits (x64): {:08X}`n"
	. "(pointer) Lower 32 bits: {:08X}`n"
	. "(pointer) Upper 32 bits (x64): {:08X}`n"
	. "PSP Memory Base Address: {:p}`n"
	. "PSP Memory Base Pointer: {:p}`n"
	. "Process Base Address: {:p}`n"
	. "Base Offset to PSP Memory Base Pointer: {:08X}`n"
	, ppsspp_WindowClass
	, ppsspp_ProcessHwnd
	, ppsspp_ProcessName
	, ppsspp_Is64BitProcess
	, Reply0, Reply1, Reply2, Reply3
	, psp_MemoryBaseAddress
	, psp_MemoryBasePointer
	, ppsspp_ProcessBaseAddress
	, ppsspp_BaseOffset )
return


ButtonRefresh:
gosub ResetVars
gosub UpdateGUI
gosub MainLogic
return


WindowOutputGuiClose:
WindowOutputGuiEscape:
ExitApp
