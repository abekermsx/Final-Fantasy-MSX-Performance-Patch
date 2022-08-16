
		DEVICE NONE
		OUTPUT "ffmsxpp.dsk"



VDP_DR:	EQU $6
VDP_DW:	EQU $7

RDSLT:	EQU $0c
CALSLT:	EQU $1c

MSXVER:	EQU $2d

CHGCPU: EQU $180

FNKSTR:	EQU $f55e
JIFFY:	EQU	$fc9e
EXPTBL:	EQU $fcc1

BDOS:	EQU $f37d
HKEYI:	EQU $fd9a
HTIMI:	EQU $fd9f

_LOGIN:	EQU $18



LoaderMemoryBase:	EQU $8000
LoaderDiskOffset:	EQU $0400

GameMemoryBase:		EQU $4000
GameDiskOffset: 	EQU $c800

BattleMemoryBase:	EQU $8000
BattleDiskOffset:	EQU $18800



VdpPort.Read:		EQU $dc02
VdpPort.Write:		EQU $dc03

VdpCommandData:		EQU $dc06
VdpCommandData.SX:	EQU $dc06
VdpCommandData.SY:	EQU $dc08
VdpCommandData.DX:	EQU $dc0a
VdpCommandData.DY:	EQU $dc0c
VdpCommandData.NX:	EQU $dc0e
VdpCommandData.NY:	EQU $dc10
VdpCommandData.CMD:	EQU $dc15
VdpCommandData.ARG:	EQU $dc16	; CMD / ARG swapped positions

TurboMode:			EQU FNKSTR-1


		INCBIN "ff.dsk"



; Verify that CTRL was pressed during boot to disable 2nd drive
		FPOS $8019 - LoaderMemoryBase + LoaderDiskOffset
		ORG $8019
verify_ctrl_boot:
		ld c,_LOGIN
		call BDOS
		ld a,h
		or a
		jr nz,.error
		ld a,l
		dec a
		ret z
.error:
		ld hl,$803a
		call $80d9
		jp $816d
		ASSERT $ <= $803a



; When running on Turbo R, enable R800 if SEL key is pressed
		FPOS $8170 - LoaderMemoryBase + LoaderDiskOffset
		ORG $8170
init:
		xor a
		ld (TurboMode),a

		ld hl,MSXVER
		ld a,(EXPTBL)
		call RDSLT
		cp 3
		jr nz,set_interrupt_handler

		in a,($aa)
		and $f0
		add a,7
		out ($aa),a
		in a,($a9)
		rlca
		rlca
		jr c,set_interrupt_handler

		ld a,$81
		ld ix,CHGCPU
		ld iy,(EXPTBL-1)
		call CALSLT

		ld a,1
		ld (TurboMode),a

; Install a custom interrupt handler to be able to use VDP S#2 as default status register
set_interrupt_handler:
		ld hl,VDP_DW
		ld a,(EXPTBL)
		call RDSLT
		inc a
		ld (interrupt_handler.out1 + 1),a
		ld (interrupt_handler.out2 + 1),a
		ld (interrupt_handler.out3 + 1),a
		ld (interrupt_handler.out4 + 1),a

		ld hl,VDP_DR
		ld a,(EXPTBL)
		call RDSLT
		inc a
		ld (interrupt_handler.in1 + 1),a

		ld hl,interrupt_handler
		ld de,FNKSTR
		ld bc,interrupt_handler.end - interrupt_handler
		ldir

		di
		ld a,$c3	; JP
		ld (HKEYI),a
		ld hl,FNKSTR
		ld (HKEYI + 1),hl
		ei
		ret

interrupt_handler:
		xor a
.out1:
		out ($99),a
		ld a,$8f
.out2:
		out ($99),a

.in1:
		in a,($99)
		add a,a
		jr nc,.no_vblank

		ld hl,JIFFY	; Abuse JIFFY for NPC animation framerate limiter
		inc (hl)

		call HTIMI

.no_vblank:
		ld a,2
.out3:
		out ($99),a
		ld a,$8f
.out4:
		out ($99),a

		pop af		; Remove RET to make sure BIOS doesn't do unwanted things

		pop ix		; Get registers back from stack
		pop iy
		pop af
		pop bc
		pop de
		pop hl
		ex af,af'
		exx
		pop af
		pop bc
		pop de
		pop hl
		ei
		ret
.end:




; When player is idle, the NPC movement/animation speed should be frame rate limited
		FPOS $56ab - GameMemoryBase + GameDiskOffset
		ORG $56ab
call_update_npc:
		jp update_npc
		ASSERT $ <= $56b5



; Limit the game speed to 12FPS
		FPOS $56f5 - GameMemoryBase + GameDiskOffset
		ORG $56f5
update_framerate_limiter:
		db 5
		ASSERT $ <= $56f6



; Optimize the routine for converting 16x16 tiles to a set of 4 8x8 tiles
		FPOS $5952 - GameMemoryBase + GameDiskOffset
		ORG $5952
convert_16x16_to_8x8:
		ld iy,$2880
		ld ix,$0100
		ld d,0

		ld c,$0d
.loop_rows:

		ld b,$10
		ld e,$80
.loop_columns:
		ld l,(iy)
		ld h,$c6
		ld a,(hl)
		ld (ix + $00),a

		add hl,de
		ld a,(hl)
		ld (ix + $01),a

		add hl,de
		ld a,(hl)
		ld (ix + $20),a

		add hl,de
		ld a,(hl)
		ld (ix + $21),a

		inc iy
		inc ix
		inc ix
		djnz .loop_columns

		ld e,$20
		add ix,de

		dec c
		jp nz,.loop_rows
		ret
		ASSERT $ <= $5994



; Don't call the old routing for copying updated tiles
		FPOS $58d4 - GameMemoryBase + GameDiskOffset
		ORG $58d4
		ret

; Don't call the old routing for copying updated tiles
		FPOS $5aa0 - GameMemoryBase + GameDiskOffset
		ORG $5aa0
		ret



; Optimize the routine for copying updated tiles
; Use the freed up space for some other routines
		FPOS $5994 - GameMemoryBase + GameDiskOffset
		ORG $5994
copy_updated_tiles:

; Set up VPD command parameters
		ld hl,8
		ld (VdpCommandData.NX),hl	; NX
		ld (VdpCommandData.NY),hl	; NY

		ld l,$d0
		ld (VdpCommandData.CMD),hl	; CMD / ARG

		xor a
		ld (VdpCommandData.SX+1),a	; SX MSB
		ld (VdpCommandData.SY+1),a	; SY MSB (page)
		ld (VdpCommandData.DX+1),a	; DX MSB

		ld a,($dc1b)
		or a
		ld a,3
		jr z,1f
		dec a
1:
		ld (VdpCommandData.DY+1),a	; DY MSB (page)

		ld a,($dc1b)
		or a
		ld hl,$2241
		ld de,$2200
		jr z,1f
		ld hl,$2581
		ld de,$2540
1:
		ld (.hl + 1),hl
		ld (.de + 1),de
		ld de,$0141
.hl:
		ld hl,$2581
		ld c,8
.loop_rows:

		ld b,16
.loop_columns:
		ld a,(de)
		cp (hl)
		jr z,.next

.copy:
		push de
		ld d,a

		ld a,b
		ld (VdpCommandData.DX),a	; DX

		ld a,c
		ld (VdpCommandData.DY),a	; DY

		ld a,d
		and %11100000
		srl a
		rrca
		ld (VdpCommandData.SY),a	; SY

		add a,a
		add a,a
		ld e,a
		ld a,d
		sub e
		rlca
		rlca
		rlca
		ld (VdpCommandData.SX),a	; SX

		pop de

		call copy_tile

.next:
		inc hl
		inc de

		ld a,b
		add a,8
		ld b,a
		cp 240
		jp nz,.loop_columns

		inc hl
		inc hl
		inc hl
		inc hl
		inc de
		inc de
		inc de
		inc de

		ld a,c
		add a,8
		ld c,a
		cp 184
		jp nz,.loop_rows

		ld hl,#0100
.de:
		ld de,#2540
		ld bc,#0340
		ldir
		ret

; Limit NPC animation/movement speed
update_npc:
		ld hl,JIFFY
		ld a,(hl)
		sub 10
		ret c
		ld (hl),0
		call $61c4
		jp $61ce

; Updated sleep routine, use R800 timer if turbo mode is enabled
sleep:
		push af
		push bc
		
		ld a,(TurboMode)
		or a
		jr nz,.turbo

.loop_b:
		ld c,0
.loop_c:
		dec c
		jr nz,.loop_c
		djnz .loop_b
		jr .end

.turbo:
		xor a
		out ($e6),a
.wait_msb:
		in a,($e7)
		or a
		jr z,.wait_msb
.wait_lsb:
		in a,($e6)
		cp 74
		jr c,.wait_lsb
		djnz .turbo
		
.end:
		pop bc
		pop af
		ret
		ASSERT $ <= $5a86
		


; Redirect all calls to sleep routine to new sleep routine		
		FPOS $5e96 - GameMemoryBase + GameDiskOffset
		ORG $5e96
		jp sleep



; Optimized the routine for executing the vdp command for copying tiles
		FPOS $703e - GameMemoryBase + GameDiskOffset
		ORG $703e
copy_tile:
		push af	; push/pop af is probably not needed
		push bc
		push hl

		ld a,(VdpPort.Read)
		ld c,a
.wait:
		in a,(c)
		rrca
		jr c,.wait

		ld a,$20
		di
		call $716c

		ld hl,VdpCommandData
		outi	;SX
		outi
		outi	;SY
		outi
		outi	;DX
		outi
		outi	;DY
		outi
		outi	;NX
		outi
		outi	;NY
		outi
		out	(c),a
		ld hl,(VdpCommandData.CMD)
		out (c),h
		ei
		out (c),l

		pop hl
		pop bc
		pop af
		ret
		ASSERT $ <= $7085



; Optimized routine for reading VDP status register
; Also makes VDP S#2 the default status register again!
; TODO: Find out if this routine is only used to read VDP S#2
		FPOS $718d - GameMemoryBase + GameDiskOffset
		ORG $718d
read_vdp_status_register:
        push bc
        ld bc,(VdpPort.Write)
        di
        out (c),a
        ld a,$8f
        out (c),a
        ld bc,(VdpPort.Read)
        in a,(c)
        push af
        ld c,b
		ld a,2
		out (c),a
		ld a,$8f
		out (c),a
		pop af
		pop bc
		ret
		ASSERT $ <= $71b1



; Convert battle speed(?) parameter and use new sleep routine to wait
		FPOS $a2be - BattleMemoryBase + BattleDiskOffset
		add a,a
		add a,a
		add a,a
		add a,a
		ld b,a
		jp sleep


		
; Redirect all calls to sleep routine to new sleep routine
		FPOS $aabe - BattleMemoryBase + BattleDiskOffset
		jp sleep
