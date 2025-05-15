; ppsspp_WS.ahk by NABN00B
; Quick tool to communicate with PPSSPP through its WebSocket API.
; Developed for and tested in AutoHotkey v1.1.31.01 to be run on x86-64 Windows.
; Compile using the "Unicode 64-bit" base file.
; The communication is logged into a file which should be read in follow mode (cat ppsspp_WS.log -Tail 5 -Wait).
; Requires the option under 'Settings -> Tools -> Developer tools -> Allow remote debugger' to be enabled.
; Requires you to set the variable `ppsspp_DiscStreamingLocalPort` to match the value under 'Settings -> Tools -> Remote disc streaming -> Settings -> Local server port'.


; AUTO-EXECUTE
#Warn All, MsgBox
#NoEnv
#Persistent
#SingleInstance Force
SetWinDelay, 0
SetWorkingDir, %A_ScriptDir%
SetBatchLines, -1

#Include <WebSocket_76a36c5>

gosub SetConfigVars
gosub ResetValues
gosub CreateGUI
gosub UpdateGUI
gosub ConnectSequence
return
; End of AUTO-EXECUTE


ResetValues:
gosub ResetVars
gosub SetMessages
gosub UpdateMessageVars
return


ConnectSequence:
gosub WaitForEmu
gosub OpenLog
gosub OpenConnection
gosub UpdateInfo
gosub UpdateGUI
gosub FocusEditBox
;gosub PromptLoop
return


SetConfigVars:
; Set this variable to match the value under 'Settings -> Tools -> Remote disc streaming -> Settings -> Local server port'.
ppsspp_DiscStreamingLocalPort := 60571
; Set this variable to the string that should be the default input in the prompt.
DefaultInput := ".version"
; Set this variable to True in order to preserve previous logs by appending to the logfile instead of overwriting it.
PreserveLogs := False
; Change the filename of the log file.
LogFileName := "ppsspp_WS.log"
return


ResetVars:
Messages := {}
MessagesList := ""
MessagesCount := 0
MessagesHeight := 180
InfoRows := 4
Info := "Waiting for a PPSSPP process to launch..."
ppsspp_WindowClass := "PPSSPPWnd"
LogFile := ""
LogFileAccessMode := 0x1 ; (over)write
if (PreserveLogs)
	LogFileAccessMode := 0x3 ; append
ppsspp_Connection := ""
UserInput := ""
PromptUser := True
return


SetMessages:
Messages[".version" ] := ("{""event"": ""version"", ""name"": ""ppsspp_WS"", ""version"": ""1.0""}")
Messages[".gReset"  ] := ("{""event"": ""game.reset""}")
Messages[".gStatus" ] := ("{""event"": ""game.status""}")
Messages[".iStart"  ] := ("{""event"": ""input.buttons.send"", ""buttons"": {""start"": true}}")
Messages[".iUnStart"] := ("{""event"": ""input.buttons.send"", ""buttons"": {""start"": false}}")
Messages[".mBase"   ] := ("{""event"": ""memory.base""}")
Messages[".mMap"    ] := ("{""event"": ""memory.mapping""}")
Messages[".mSearch" ] := ("{""event"": ""memory.info.search"", ""address"": ""0x8800000"", ""end"": ""0xC000000"", ""match"": ""BLOCKING LOAD"", ""type"":""write""}")
Messages[".mRead"   ] := ("{""event"": ""memory.read_u32"", ""address"": ""0x8BAD4EC""}")
return


UpdateMessageVars:
For key, value in Messages
{
	MessagesList .= key . "`n"
	MessagesCount += 1
}
MessagesHeight += 17 * MessagesCount
InfoRows += MessagesCount
return


CreateGUI:
Gui, WindowInput:New
Gui, WindowInput:Font, s10
Gui, WindowInput:Add, Text, r%InfoRows% w336 vTextInfo
Gui, WindowInput:Add, Edit, r1 w336 +WantCtrlA -WantReturn -Multi -ReadOnly vEditInput
Gui, WindowInput:Add, Button, w162 Section gButtonReset vButtonReset, Reset Connection
Gui, WindowInput:Add, Button, w162 ys Default gButtonSend vButtonSend, Send Message
;GuiControl, Disable, ButtonSend
Gui, WindowInput:Show, AutoSize
return


UpdateGUI:
GuiControl, , TextInfo, %Info%
GuiControl, , EditInput, %DefaultInput%
return


WaitForEmu:
WinWait, ahk_class %ppsspp_WindowClass%
return


OpenLog:
LogFile := FileOpen(LogFileName, 0x100 + LogFileAccessMode)
if (LogFile)
	LogFile.Position := LogFile.Length
else
	MsgBox, Failed to open %LogFileName%.`nThe program will output events to the system debugger.
return


OpenConnection:
ppsspp_Connection := new WebSocket("ws://127.0.0.1:" . ppsspp_DiscStreamingLocalPort . "/debugger", EventHandlers)
if (ppsspp_Connection)
{
	while (!ppsspp_Connection.readyState)
		Sleep, 1000
}
return


class EventHandlers
{
	Open(Event) ; {timestamp: 0, url: "" }
	{
		LogWriteLine(Event.timestamp . " [open] Connection opened at URL: " . Event.url)
		OutputDebug % "Open: " Event.timestamp " - " Event.url "`n"
		;MsgBox, % "WebSocket Connected at Timestamp:`n" . Event.timestamp
	}

	Message(Event) ; { data: "" }
	{
		LogWriteLine(A_Now . A_Msec . " [recv] " . Event.data)
		OutputDebug % "Message: " Event.data "`n"
	}

	Data(Event) ; { data: &, size: 0 }
	{
		LogWriteLine(A_Now . A_Msec . " [data] Receiving data of size " . Event.size . "`n" . Event.data)
		OutputDebug % "Receiving " Event.size " bytes`n"
		VarSetCapacity(data, Event.size, 0)
		DllCall("RtlMoveMemory", "Ptr",&data, "Ptr",Event.data, "Ptr",Event.size)
		; `data` has now a binary buffer
	}

	Error(Event) ; { code: 0 }
	{
		LogWriteLine(A_Now . A_Msec . " [eror] " . Event.code)
		OutputDebug % "Error: " Event.code "`n"
		MsgBox, % "WebSocket Error:`n" . Event.code
	}

	Close(Event) ; { reason: "", status: 0 }
	{
		LogWriteLine(A_Now . A_Msec . " [clos] " . Event.reason . "(Status: " . Event.status . ")")
		OutputDebug % "Close: " Event.reason " (Status: " Event.status ")`n"
	}
}


LogWriteLine(ByRef content)
{
	global LogFile
	bytesWritten := FileWriteLineCommit(LogFile, content)
	if (bytesWritten <= 0)
		OutputDebug, %content%
	return bytesWritten
}


FileWriteLineCommit(ByRef file, ByRef content)
{
	bytesWritten := 0
	if (file)
	{
		bytesWritten := file.WriteLine(content)
		file.__Handle ; Commit to disk, flush buffer.
	}
	else
		bytesWritten := -1
	return bytesWritten
}


UpdateInfo:
if (ppsspp_Connection)
	Info := "Enter predefined event to send through the WebSocket:`n" . MessagesList . "`n... or type in a custom message in JSON format eg.`n{""event"": ""version"", ""name"": ""hello"", ""version"": ""1.0""}"
else
	Info := "Failed to connect to PPSSPP."
return


FocusEditBox:
GuiControl, Focus, EditInput
return


ButtonSend:
GuiControlGet, UserInput, , EditInput
ws_SendMessage(ppsspp_Connection, ProcessInput(UserInput))
gosub FocusEditBox
return


ProcessInput(rawInput) ; copy parameter value
{
	global Messages
	processedInput := ""
	if (Messages[rawInput])
		processedInput := Messages[rawInput]
	else
		processedInput := rawInput
	return processedInput
}


ws_SendMessage(ByRef connection, ByRef message)
{
	if (connection.readyState == 1)
	{
		connection.Send(message)
		LogWriteLine(A_Now . A_Msec . " [send] " . message)
		return true
	}
	return false
}


ButtonReset:
gosub DisconnectSequence
gosub ResetValues
gosub UpdateGUI
gosub ConnectSequence
return


DisconnectSequence:
gosub CloseConnection
gosub CloseLog
return


CloseConnection:
LogWriteLine(A_Now . A_Msec . " [exit] Exit sequence called.")
if (ppsspp_Connection)
{
	ppsspp_Connection.shutdown()
	while (ppsspp_Connection.readyState != 3)
		Sleep, 1000
	ppsspp_Connection.__Delete()
}
LogWriteLine(A_Now . A_Msec . " [exit] Exit sequence over.")
return


CloseLog:
if (LogFile)
	LogFile.Close()
return


WindowInputGuiClose:
WindowInputGuiEscape:
gosub DisconnectSequence
ExitApp


/*
PromptLoop:
while (ppsspp_Connection.readyState == 1 && PromptUser)
{
	PromptUser := NewMessage(ppsspp_Connection)
	if (PromptUser)
		Sleep, 1000
}
return


NewMessage(ByRef connection)
{
	global DefaultInput, Messages, MessagesList, MessagesHeight
	InputBox, inputValue, , Enter predefined event to send through the WebSocket:`n%MessagesList%`n... or type in a custom message in JSON format eg.`n{"event": "version"`, "name": "hello"`, "version": "1.0"}, , 360, %MessagesHeight%, , , , , %DefaultInput%
	if (!ErrorLevel)
		ws_SendMessage(connection, ProcessInput(inputValue))
	return !ErrorLevel
}
*/