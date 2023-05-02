
; Install a custom interrupt handler to be able to use VDP S#2 as default status register
		FPOS $8200 - Sector3MemoryBase + Sector3FileOffset
		ORG $8200
set_interrupt_handler:
		ld hl,data
		ld de,KBUF
		ld bc,data_end - data_start
		ldir

		ld hl,VDP_DW
		ld a,(EXPTBL)
		call RDSLT
		inc a
		ld (wrtvdp.out1 + 1),a
		ld (wrtvdp.out2 + 1),a

		ld hl,VDP_DR
		ld a,(EXPTBL)
		call RDSLT
		inc a
		ld (set_default_interrupt_handler.in1 + 1),a
		ld (interrupt_handler.in1 + 1),a
		ld (interrupt_handler.in2 + 1),a

		ld hl,HKEYI
		ld de,hkeyi_backup
		ld bc,3
		ldir
		
		call set_game_interrupt_handler
		ret

data:
		ORG KBUF
data_start:

set_game_interrupt_handler:
		di
		ld a,$c3	; JP
		ld (HKEYI),a
		ld hl,interrupt_handler
		ld (HKEYI + 1),hl
		
		ld bc,1 * 256 + $80 + 19
		call wrtvdp
		
        ld hl,RG0SAV
        ld a,(hl)
        or 16			; enable line interrupts
        ld (hl),a

		ld b,a
		ld c,$80
.end:
		call wrtvdp
		ei
		ret
		
set_default_interrupt_handler:
		di
		ld hl,hkeyi_backup
		ld de,HKEYI
		ld bc,3
		ldir
		
		ld hl,RG0SAV
		ld a,(hl)
		and %11101111	; disable line interrupts
		ld (hl),a
		
		ld b,a
		ld c,$80
		call wrtvdp
		
		ld bc,1 * 256 + $80 + 15
		call wrtvdp		; select S#0 so we can check line interrupt

.in1:
		in a,($99)		; make sure to clear potential pending line interrupt
		
		ld bc,0 * 256 + $80 + 15	; select S#0 so BIOS can check vblank interrupt
		jr set_game_interrupt_handler.end
		

; Write data to VDP register
; In: B: data
;     C: register (with bit 7 set!)
wrtvdp:
		ld a,b
.out1:
		out ($99),a
		ld a,c
.out2:
		out ($99),a
		ret
		

hkeyi_backup:
		ds 3


; Helper routine to read from keyboard
; BIOS routine CHGET needs original HKEYI to be able to read from keyboard 
chget_helper:
		call set_default_interrupt_handler
		call CALSLT
		push af
		call set_game_interrupt_handler
		pop af
		ret
		

; Custom interrupt handler to use during game
; Main purpose is to keep VDP S#2 as default register during normal game, to be able to quickly check if VDP command is still being executed
; When a line interrupt occurs, the HTIMI hook is called which will in turn will call the music replay routine
interrupt_handler:
		ld bc,0 * 256 + $80 + 15
		call wrtvdp	; select S#0 so we can check if it's vblank interrupt

.in1:
		in a,($99)
		add a,a
		jr c,.vblank

		inc b
		call wrtvdp ; select S#1 so we can check if it's line interrupt

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
		ld bc,2 * 256 + $80 + 15
		call wrtvdp ; select S#2 again to be able to quickly check if VDP command is being executed

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

		ASSERT $ <= BUFMIN
