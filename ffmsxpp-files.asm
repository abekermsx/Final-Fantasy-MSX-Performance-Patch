
		DEVICE NONE

		INCLUDE "include/msx.asm"
		INCLUDE "include/variables.asm"

; Loader code in sector 2 & 3
Sector2MemoryBase:	EQU $8000
Sector2FileOffset:	EQU 0
Sector3MemoryBase:	EQU $8200
Sector3FileOffset:	EQU 0

; MAIN.COM
MainMemoryBase:		EQU $4000
MainFileOffset:		EQU 0

; SMAP.COM
SmapMemoryBase:		EQU $8000
SmapFileOffset:		EQU 0

; BATTLE.COM
BattleMemoryBase:	EQU $8000
BattleFileOffset:	EQU 0

; STARTUP.COM
StartupFileOffset:	EQU 0

		OUTPUT "out/0002.bin"
		INCBIN "data/sectors/0002.bin"
		INCLUDE "patch/0002.asm"

		OUTPUT "out/0003.bin"
		INCBIN "data/sectors/0003.bin"
		INCLUDE "patch/0003.asm"
		
		OUTPUT "out/MAIN.COM"
		INCBIN "data/files/MAIN.COM"
		INCLUDE "patch/main.asm"

		OUTPUT "out/SMAP.COM"
		INCBIN "data/files/SMAP.COM"
		INCLUDE "patch/smap.asm"

		OUTPUT "out/BATTLE.COM"
		INCBIN "data/files/BATTLE.COM"
		INCLUDE "patch/battle.asm"

		OUTPUT "out/STARTUP.COM"
		INCBIN "data/files/STARTUP.COM"
		INCLUDE "patch/startup.asm"
