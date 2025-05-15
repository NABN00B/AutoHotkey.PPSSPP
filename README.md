# AutoHotkey.PPSSPP
A collection of AutoHotkey scripts to manipulate PPSSPP memory.

## Terminology
Note that all of the addresses and offsets below represent a `PPSSPPWindows64.exe` process running on x86-64 Windows.  
A `PPSSPPWindows.exe` process running on x86-64 Windows has addressess and offsets that are "similar" enough to be recognisable, but they are all in 32 bits.

**PSP Memory Base Address**: the address in Windows memory where the emulated PSP's memory starts from (`0x0` in PSP memory). Usually something like `0x0000_01??_????_???` or `0x0000_02??_????_????`. 

**PSP Memory Base Pointer**: the pointer to PSP Memory Base Address. The address where the value is the address in Windows memory where the emulated PSP's memory starts from. Its value is the `PSP Memory Base Address`. Its address is usually something like `0x0000_7ff?_????_????`.

**PSP User Memory Address**: the address `0x0880_0000` in the emulated PSP's memory where game data starts from. (Mind the different characters!) The addresses of game variables (**offset1** in pointer paths) are higher than this (already contain `0x0880_0000`).

**PPSSPP Process Base Address**: the address in Windows memory where the memory of a `PPSSPPWindows64.exe` process starts from. Often referred to as **PPSSPPWindows64.exe**. Usually something like `0x0000_7ff?_????_????`.

**PPSSPP Base Offset (to PSP Memory Base Pointer)**: the offset in Windows memory, such that  
`PPSSPP Process Base Address + PPSSPP Process Base Offset == address of PSP Memory Base Pointer`.  
Seems to be between `0x00A0_0000` and `0x0100_0000`. A constant that is usually different for each build.

## Files
- **[ppsspp_WM.ahk](ppsspp_WM.ahk)** -- A tool that retrieves the `PSP Memory Base Address/Pointer` via window messages and calculates the `Base Offset to PSP Memory Base Pointer`. Useful for everyday hacking and also serves as a demonstration.
- **[ppsspp_WS.ahk](ppsspp_WS.ahk)** -- A tool that communicates with PPSSPP through its WebSocket API. Currently it is still in an experimental state and isn't asynchronous yet.
