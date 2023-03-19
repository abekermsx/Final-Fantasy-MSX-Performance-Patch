
		DEVICE NONE
		OUTPUT "ffmsxpp.dsk"

		INCLUDE "include/msx.asm"
		INCLUDE "include/variables.asm"

; Loader code in sector 2
LoaderMemoryBase:	EQU $8000
LoaderFileOffset:	EQU $0400

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

		INCBIN "ff.dsk"

		INCLUDE "patch/loader.asm"
		INCLUDE "patch/main.asm"
		INCLUDE "patch/smap.asm"
		INCLUDE "patch/battle.asm"
		INCLUDE "patch/startup.asm"
