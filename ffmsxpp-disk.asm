
		DEVICE NONE
		OUTPUT "out/ffmsxpp.dsk"

		INCLUDE "include/msx.asm"
		INCLUDE "include/variables.asm"

; Loader code in sector 2 & 3
Sector2MemoryBase:	EQU $8000
Sector2FileOffset:	EQU $0400
Sector3MemoryBase:	EQU $8200
Sector3FileOffset:	EQU $0600

; MAIN.COM
MainMemoryBase:		EQU $4000
MainFileOffset:		EQU $c800

; SMAP.COM
SmapMemoryBase:		EQU $8000
SmapFileOffset:		EQU $10800

; BATTLE.COM
BattleMemoryBase:	EQU $8000
BattleFileOffset:	EQU $18800

; STARTUP.COM
StartupFileOffset:	EQU $1c800

		INCBIN "data/ff.dsk"

		INCLUDE "patch/0002.asm"
		INCLUDE "patch/0003.asm"
		INCLUDE "patch/main.asm"
		INCLUDE "patch/smap.asm"
		INCLUDE "patch/battle.asm"
		INCLUDE "patch/startup.asm"
