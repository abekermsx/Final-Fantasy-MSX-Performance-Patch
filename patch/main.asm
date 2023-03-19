
; Use new sleep routine in 'window' effect
		FPOS $5657 - MainMemoryBase + MainFileOffset
		ORG $5657
		push bc
		ld b,3
		call sleep
		pop bc
		ret
		ASSERT $ <= $5663
		
		
		
; When player is idle, the NPC movement/animation speed should be frame rate limited
		FPOS $56ab - MainMemoryBase + MainFileOffset
		ORG $56ab
call_update_npc:
		jp update_npc
		ASSERT $ <= $56b5



; Limit the game speed to 12FPS
		FPOS $56f5 - MainMemoryBase + MainFileOffset
		ORG $56f5
update_framerate_limiter:
		db 5
		ASSERT $ <= $56f6



; Optimize the routine for converting 16x16 tiles to a set of 4 8x8 tiles
		FPOS $5952 - MainMemoryBase + MainFileOffset
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
		FPOS $58d4 - MainMemoryBase + MainFileOffset
		ORG $58d4
		ret

; Don't call the old routine for copying updated tiles
		FPOS $5aa0 - MainMemoryBase + MainFileOffset
		ORG $5aa0
		ret



; Optimize the routine for copying updated tiles
; Use the freed up space for some other routines
		FPOS $5994 - MainMemoryBase + MainFileOffset
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
		FPOS $5ace - MainMemoryBase + MainFileOffset
		ORG $5ace
		jp fast_ldir
		ASSERT $ <= $5ad1



; Redirect all calls to sleep routine to new sleep routine
		FPOS $5e96 - MainMemoryBase + MainFileOffset
		ORG $5e96
		jp sleep
		ASSERT $ <= $5ea0



; Optimized the routine for executing the vdp command for copying tiles
		FPOS $703e - MainMemoryBase + MainFileOffset
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
		FPOS $716c - MainMemoryBase + MainFileOffset
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
		FPOS $717e - MainMemoryBase + MainFileOffset
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
		FPOS $718d - MainMemoryBase + MainFileOffset
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
		FPOS $7417 - MainMemoryBase + MainFileOffset
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
		FPOS $78a2 - MainMemoryBase + MainFileOffset
		ORG $78a2
		jp fast_ldir_c
		ASSERT $ <= $78a5



; Optimized music event table scan
		FPOS $7729 - MainMemoryBase + MainFileOffset
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
		FPOS $7951 - MainMemoryBase + MainFileOffset
		ORG $7951
		call fast_hl_div_8
		ASSERT $ <= $7954



; Slightly faster ADD_HL_A
		FPOS $7994 - MainMemoryBase + MainFileOffset
		ORG $7994
add_hl_a:
		add a,l
		ld l,a
		ret nc
		inc h
		ret
		ASSERT $ <= $799a



; Init msx music out routine for R800 if needed
		FPOS $752f - MainMemoryBase + MainFileOffset
		ORG $752f
		call init_msx_music_out
		ASSERT $ <= $7532
		


; Faster psg out
		FPOS $7f81 - MainMemoryBase + MainFileOffset
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
		FPOS $7f91 - MainMemoryBase + MainFileOffset
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
