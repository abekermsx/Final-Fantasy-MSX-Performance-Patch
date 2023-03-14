
		DEVICE NONE
		OUTPUT "ffmsxpp.dsk"



VDP_DR:	EQU $6
VDP_DW:	EQU $7

RDSLT:	EQU $0c
CALSLT:	EQU $1c

MSXVER:	EQU $2d

CHGCPU: EQU $180

RG0SAV:	EQU $f3df
BUF:	EQU $f55e
TTYPOS:	EQU	$f661
JIFFY:	EQU	$fc9e
EXPTBL:	EQU $fcc1

BDOS:	EQU $f37d
HKEYI:	EQU $fd9a
HTIMI:	EQU $fd9f

RG9SAV: EQU $ffe8

_LOGIN:	EQU $18



LoaderMemoryBase:	EQU $8000
LoaderDiskOffset:	EQU $0400

; MAIN.COM
GameMemoryBase:		EQU $4000
GameDiskOffset: 	EQU $c800

; SMAP.COM
TownMemoryBase:		EQU $8000
TownDiskOffset:		EQU $10800

; BATTLE.COM
BattleMemoryBase:	EQU $8000
BattleDiskOffset:	EQU $18800

; STARTUP.COM
StartUpDiskOffset:	EQU $1c800



VdpPort.Vram:		EQU $dc01
VdpPort.Read:		EQU $dc02
VdpPort.Write:		EQU $dc03
VdpPort.WriteIndirect:		EQU $dc05

VdpCommandData:		EQU $dc06
VdpCommandData.SX:	EQU $dc06
VdpCommandData.SY:	EQU $dc08
VdpCommandData.DX:	EQU $dc0a
VdpCommandData.DY:	EQU $dc0c
VdpCommandData.NX:	EQU $dc0e
VdpCommandData.NY:	EQU $dc10
VdpCommandData.CMD:	EQU $dc15
VdpCommandData.ARG:	EQU $dc16	; CMD / ARG swapped positions



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



; When running on Turbo R, enable R800 unless SEL key is pressed
		FPOS $8170 - LoaderMemoryBase + LoaderDiskOffset
		ORG $8170
init:
		xor a
		ld (TurboMode),a
		ld a,5
		ld (MusicEqualizer),a

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
		jr nc,set_interrupt_handler

		ld a,$81
		ld ix,CHGCPU
		ld iy,(EXPTBL-1)
		call CALSLT

		ld a,1
		ld (TurboMode),a

; Install a custom interrupt handler to be able to use VDP S#2 as default status register
set_interrupt_handler:
		ld hl,data
		ld de,BUF
		ld bc,data_end - data_start
		ldir

		ld hl,VDP_DW
		ld a,(EXPTBL)
		call RDSLT
		inc a
		ld (interrupt_handler.out1 + 1),a
		ld (interrupt_handler.out2 + 1),a
		ld (interrupt_handler.out3 + 1),a
		ld (interrupt_handler.out4 + 1),a
		ld (interrupt_handler.out5 + 1),a
		ld (interrupt_handler.out6 + 1),a

		push af

		ld hl,VDP_DR
		ld a,(EXPTBL)
		call RDSLT
		inc a
		ld (interrupt_handler.in1 + 1),a
		ld (interrupt_handler.in2 + 1),a

		ld a,$c3	; JP
		ld (HKEYI),a
		ld hl,BUF
		ld (HKEYI + 1),hl

		pop af
		ld c,a
		ld a,1
		out (c),a
		ld a,$80 + 19
		out (c),a

		ld a,(RG0SAV)
		or 16
		ld (RG0SAV),a
		out (c),a
		ld a,$80
		ei
		out (c),a
		ret

data:
		ORG BUF
data_start:
interrupt_handler:
		xor a
.out1:
		out ($99),a
		ld a,$8f
.out2:
		out ($99),a	; select S#0 so we can check if it's vblank interrupt

.in1:
		in a,($99)
		add a,a
		jr c,.vblank

		ld a,1
.out3:
		out ($99),a
		ld a,$8f
.out4:
		out ($99),a	; select S#1 so we can check if it's line interrupt

.in2:
		in a,($99)
		rra
		jr nc,.end

.hblank:
		call HTIMI
		jr .end

.vblank:
		ld hl,JIFFY	; Abuse JIFFY for NPC animation framerate limiter
		inc (hl)

		ld hl,$dc1d
		inc (hl)

.end:
		ld a,2
.out5:
		out ($99),a
		ld a,$8f
.out6:
		out ($99),a	; select S#2 again to be able to quickly check if VDP command is being executed

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

; A fast otir routine, assuming DE is a multiple of 16
fast_otir_de:
		ld b,e
		inc d
.loop:
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		outi
		jp nz,.loop
		dec d
		jp nz,.loop
		ret

; A fast ldir routine, assuming BC is multiple of 16
fast_ldir:
fast_ldir_10:	ldi
fast_ldir_f:	ldi
fast_ldir_e:	ldi
fast_ldir_d:	ldi
fast_ldir_c:	ldi
fast_ldir_b:	ldi
fast_ldir_a:	ldi
fast_ldir_9:	ldi
fast_ldir_8:	ldi
fast_ldir_7:	ldi
fast_ldir_6:	ldi
fast_ldir_5:	ldi
fast_ldir_4:	ldi
fast_ldir_3:	ldi
fast_ldir_2:	ldi
fast_ldir_1:	ldi
		jp pe,fast_ldir
		ret

; Fast HL/8 using just shifts
fast_hl_div_8:
		srl h
		rr l	; /2
		srl h
		rr l	; /4
		srl h
		rr l	; /8
		ret

; Replace the default MSX Music out routine with one suitable for R800 mode if necessary
init_msx_music_out:
		ld a,(TurboMode)
		or a
		jr z,.end
		
		ld a,$c3	; JP
		ld ($7f91),a
		ld hl,r800_msx_music_out
		ld ($7f92),hl
		
.end:
		ld hl,$bd00
		ret

; MSX Music out routine suitable for R800
r800_msx_music_out:
        push af
		push bc

        ld a,(R800WaitCounter)
        ld b,a
.wait:  
		in a,($e6)
        sub b
        cp 6
        jr c,.wait
		
		pop bc
		
        ld a,b
        di
        out ($7c),a
        in a,($e6)
		ld (R800WaitCounter),a
        pop af
        out ($7d),a
        ret

; Play the music the same speed on 50hz as on 60hz
music_play:
		call $75d4
		ld a,(RG9SAV)
		and 2
		ret z
		ld hl,MusicEqualizer
		dec (hl)
		ret nz
		ld (hl),5
		jp $75d4

data_end:

MusicEqualizer:	 db 0
R800WaitCounter: db 0
TurboMode:		 db 0

		ASSERT $ <= TTYPOS



; Use new sleep routine in 'window' effect
		FPOS $5657 - GameMemoryBase + GameDiskOffset
		ORG $5657
		push bc
		ld b,3
		call sleep
		pop bc
		ret
		ASSERT $ <= $5663
		
		
		
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
		inc ixl		; IX doesn't cross 256 byte boundary while looping columns
		inc ixl
		djnz .loop_columns

		ld e,$20
		add ix,de

		dec c
		jp nz,.loop_rows
		ret
		ASSERT $ <= $5994



; Don't call the old routine for copying updated tiles
		FPOS $58d4 - GameMemoryBase + GameDiskOffset
		ORG $58d4
		ret

; Don't call the old routine for copying updated tiles
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
		ld ix,$238e
		jr z,1f
		ld hl,$2581
		ld de,$2540
		ld ix,$26ce
1:
		ld (.hl + 1),hl
		ld (.de + 1),de
		ld de,$0141
.hl:
		ld hl,$2581

		ld a,$ff
		ld (ix + $00),a
		ld (ix + $01),a
		ld (ix + $20),a
		ld (ix + $21),a

		ld c,8
.loop_rows:

		ld b,16
.loop_columns:
		ld a,(de)
		cp (hl)
		jr z,.next

.copy:
		ld ixl,a
		and %11100000
		rrca
		rrca
		ld (VdpCommandData.SY),a	; SY
		
		ld a,ixl
		and %00011111
		rlca
		rlca
		rlca
		ld (VdpCommandData.SX),a	; SX

		ld a,b
		ld (VdpCommandData.DX),a	; DX

		ld a,c
		ld (VdpCommandData.DY),a	; DY

		call copy_tile

.next:
		inc l
		inc e

		ld a,b
		add a,8
		ld b,a
		cp 240
		jp nz,.loop_columns

		inc l
		inc l
		inc hl	; crossing 256 byte boundary here
		inc l
		inc e
		inc e
		inc de	; crossing 256 byte boundary here
		inc e

		ld a,c
		add a,8
		ld c,a
		cp 184
		jp nz,.loop_rows

		ld hl,$0100
.de:
		ld de,$2540
		ld bc,$0340
		jp fast_ldir

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



; Use fast ldir routine to copy map
		FPOS $5ace - GameMemoryBase + GameDiskOffset
		ORG $5ace
		jp fast_ldir
		ASSERT $ <= $5ad1



; Redirect all calls to sleep routine to new sleep routine
		FPOS $5e96 - GameMemoryBase + GameDiskOffset
		ORG $5e96
		jp sleep
		ASSERT $ <= $5ea0



; Optimized the routine for executing the vdp command for copying tiles
		FPOS $703e - GameMemoryBase + GameDiskOffset
		ORG $703e
copy_tile:
		push af	; push/pop af is probably not needed
		push bc
		push hl

		ld a,$20
		di
		call $716c
		ei
		ld b,c

		ld hl,VdpCommandData
		
		ld a,(VdpPort.Read)
		ld c,a
.wait:
		in a,(c)
		rrca
		jr c,.wait

		ld c,b

		di
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



; Setup VDP write register indirect
		FPOS $716c - GameMemoryBase + GameDiskOffset
		ORG $716c
		ld b,a
		ld a,($dc03)
		ld c,a
		out (c),b
		ld a,$91
		out (c),a
		ld a,($dc05)
		ld c,a
		ld a,b
		ret
		ASSERT $ <= $717e



; Optimized routine for checking if VDP command has completed
		FPOS $717e - GameMemoryBase + GameDiskOffset
		ORG $717e
wait_vdp_command_completion:
		push af
		push bc

		ld a,(VdpPort.Read)
		ld c,a
.wait:
		in a,(c)
		rrca
		jr c,.wait

		pop bc
		pop af
		ret
		ASSERT $ <= $718d



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



; A faster routine for setting up VRAM address
		FPOS $7417 - GameMemoryBase + GameDiskOffset
		ORG $7417
set_vram_pointer:
		ex af,af'

		ld a,(VdpPort.Write)
		ld c,a

		ld a,h
        and $c0
        or b
        rlca
        rlca
        di
        out (c),a
        ld a,$8e
        out (c),a
        ld a,l
        out (c),a
		ex af,af'
		or a
        ld a,h
		jr z,.read

.write:
        and $3f
        or $40
		out (c),a
		ld a,(VdpPort.Vram)
		ld c,a
		ret

.read:
		and $3f
		out (c),a
		ld a,(VdpPort.Vram)
		ld c,a
		ret
		ASSERT $ <= $7459



; Use fast ldir routine
		FPOS $78a2 - GameMemoryBase + GameDiskOffset
		ORG $78a2
		jp fast_ldir_c
		ASSERT $ <= $78a5



; Optimized music event table scan
		FPOS $7729 - GameMemoryBase + GameDiskOffset
		ORG $7729
scan_music_event_table:
		ld hl,$7716
		push hl
		ld l,$3f
		sub (hl)
		jr c,.found
.loop:
		inc l		; table doesn't cross 256 byte boundary
		inc l
		inc l
		sub (hl)
		jr nc,.loop
.found:
		add a,(hl)
		inc l
		ld e,(hl)
		inc l
		ld d,(hl)
		ex de,hl
		jp (hl)
		ASSERT $ <= $773f



; Use fast HL/8 instead of slow HL/DE
		FPOS $7951 - GameMemoryBase + GameDiskOffset
		ORG $7951
		call fast_hl_div_8
		ASSERT $ <= $7954



; Slightly faster ADD_HL_A
		FPOS $7994 - GameMemoryBase + GameDiskOffset
		ORG $7994
add_hl_a:
		add a,l
        ld l,a
        ret nc
        inc h
        ret
		ASSERT $ <= $799a



; Init msx music out routine for R800 if needed
		FPOS $752f - GameMemoryBase + GameDiskOffset
		ORG $752f
		call init_msx_music_out
		ASSERT $ <= $7532
		


; Faster psg out
		FPOS $7f81 - GameMemoryBase + GameDiskOffset
		ORG $7f81
fast_psg_out:
		di
		ld c,a
		ld a,b
		out ($a0),a
		ld a,c
		out ($a1),a
		ret
		ASSERT $ <= $7f8a



; Faster msx music out (Z80 only)
		FPOS $7f91 - GameMemoryBase + GameDiskOffset
		ORG $7f91
fast_msx_music_out:
        di
        push af
        ld a,b
        out ($7c),a
        pop af
		nop
        out ($7d),a
        ret
		ASSERT $ <= $7fa2



; Faster sprites copy routine
		FPOS $81a3 - TownMemoryBase + TownDiskOffset
		ORG $81a3
copy_sprites:
		ld a,(ix + 4)
		sla a
		sla a
		ld b,a
		sla a
		add a,b
		ld d,0
		ld e,a
		ld iy,$8218
		add iy,de
		ld a,(ix + 6)
		or a
		jr z,1f
		ld e,6
		add iy,de	; IY points to SX/SY values
1:
		ld a,($80dd)
		sla a
		ld b,a
		sla a
		add a,b
		ld hl,$8248
		add a,l		; HL doesn't cross 256 byte boundary
		ld l,a		; HL points to DX/DY values

		xor a
		ld (VdpCommandData.SX + 1),a
		ld (VdpCommandData.SY + 1),a
		ld (VdpCommandData.DX + 1),a
		ld a,3
		ld (VdpCommandData.DY + 1),a
		ld de,$40
		ld (VdpCommandData.NX),de
		ld e,$1
		ld (VdpCommandData.NY),de
		
		ld b,a
.loop:
		ld a,(iy)
		ld (VdpCommandData.SX),a
		inc iyl		; IY doesn't cross 256 byte boundary
		ld a,(ix + 5)
		sla a
		ld d,a
		sla a
		add a,d
		add a,(iy)
		ld (VdpCommandData.SY),a
		inc iyl
		ld a,(hl)
		ld (VdpCommandData.DX),a
		inc l		; HL doesn't cross 256 byte boundary
		ld a,(hl)
		ld (VdpCommandData.DY),a
		inc l
		call $7025
		djnz .loop
		ret
		ASSERT $ <= $8218



; Use fast ldir routine
		FPOS $8308 - TownMemoryBase + TownDiskOffset
		ORG $8308
		jp fast_ldir
		ASSERT $ <= $830b
		
		

; Use fast otir routine to copy sprite colors
		FPOS $8389 - TownMemoryBase + TownDiskOffset
		ORG $8389
		call fast_otir_de
		ei
		ret
		ASSERT $ <= $8392



; Convert battle speed(?) parameter and use new sleep routine to wait
		FPOS $a2be - BattleMemoryBase + BattleDiskOffset
		add a,a
		add a,a
		add a,a
		add a,a
		ld b,a
		jp sleep
		ASSERT $ <= $a2cc



; Redirect all calls to sleep routine to new sleep routine
		FPOS $aabe - BattleMemoryBase + BattleDiskOffset
		jp sleep
		ASSERT $ <= $aac7



; Call music routine directly without all push/pop
		FPOS $1d7e2	; In STARTUP.COM
		ORG $bf70
		jp music_play	;$75d4
		ASSERT $ < $bf8b
