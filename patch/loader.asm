
; Verify that CTRL was pressed during boot to disable 2nd drive
		FPOS $8019 - LoaderMemoryBase + LoaderFileOffset
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
		FPOS $8170 - LoaderMemoryBase + LoaderFileOffset
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

.line_interrupt:
		call HTIMI
		jr .end

.vblank:
		ld hl,JIFFY	; Abuse JIFFY for NPC animation framerate limiter
		inc (hl)

		ld hl,FrameCounter
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
