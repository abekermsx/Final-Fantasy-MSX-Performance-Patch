
        DEVICE NOSLOT64K
        OUTPUT "ffmsxpp.ips"

		MACRO PatchAddress address
		db ((address) >> 16) & 255
		db ((address) >> 8) & 255
		db ((address)) & 255
		ENDM

		MACRO PatchSize size
		db ((size) >> 8) & 255
		db ((size)) & 255
		ENDM

DiskOffset: equ $8800

VdpPort.Read:	equ $dc02
VdpPort.Write:	equ $dc03

VdpCommandData:		equ $dc06
VdpCommandData.SX:	equ $dc06
VdpCommandData.SY:	equ $dc08
VdpCommandData.DX:	equ $dc0a
VdpCommandData.DY:	equ $dc0c
VdpCommandData.NX:	equ $dc0e
VdpCommandData.NY:	equ $dc10
VdpCommandData.CMD:	equ $dc15
VdpCommandData.ARG:	equ $dc16	; CMD / ARG swapped positions

Jiffy:	equ	$fc9e


		db "PATCH"


; When player is idle, the NPC movement/animation speed should be frame rate limited
		PatchAddress $56ab + DiskOffset
		PatchSize call_update_npc.end - call_update_npc

		org $56ab
call_update_npc:
		call copy_tile.update_npc
		ret
.end:
		ASSERT call_update_npc.end <= $56b5



; Limit the game speed to 12FPS
		PatchAddress $56f5 + DiskOffset
		PatchSize update_framerate_limiter.end - update_framerate_limiter

		org $56f5
update_framerate_limiter:
		db 5
update_framerate_limiter.end
		ASSERT update_framerate_limiter.end <= $56f6



; Optimize the routine for converting 16x16 tiles to a set of 4 8x8 tiles
		PatchAddress $5952 + DiskOffset
		PatchSize convert_16x16_to_8x8.end - convert_16x16_to_8x8

		org $5952
convert_16x16_to_8x8:
		ld iy,$2880
		ld ix,$0100
		ld d,0

		ld c,$0d
.loop_rows:

		ld b,$10
.loop_columns:
		ld e,$80

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
.end:
		ASSERT convert_16x16_to_8x8.end <= $5994



; Optimize the routine for copying tiles
		PatchAddress $5a0b + DiskOffset
		PatchSize copy_tiles.end - copy_tiles

		org $5a0b
copy_tiles:
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

		ld hl,$0440
.loop:
		ld a,(hl)
		ld d,a
		inc a
		ret z

		inc hl
		ld a,(hl)
		add a,a
		add a,a
		add a,a
		add a,16
		ld (VdpCommandData.DX),a	; DX

		inc hl
		ld a,(hl)
		add a,a
		add a,a
		add a,a
		add a,8
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

		call $703e

		inc hl
		jp .loop

.end:
		ASSERT copy_tiles.end <= $5a86



; Optimized the routine for executing the vdp command for copying tiles
; Use the freed up space for the routine to limit NPC animation/movement speed when player is idle
		PatchAddress $704a + DiskOffset
		PatchSize copy_tile.end - copy_tile

		org $704a
copy_tile:
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
.update_npc:
		ld hl,Jiffy
		ld a,(hl)
		sub 10
		ret c
		ld (hl),0
		call $61c4
		jp $61ce
.end:
		ASSERT copy_tile.end <= $7085



; Optimized routine for reading VDP status register
		PatchAddress $718d + DiskOffset
		PatchSize read_vdp_status_register.end - read_vdp_status_register

		org $718d
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
		xor a
		out (c),a
		ld a,$8f
		out (c),a
		pop af
		pop bc
		ret
.end:
		ASSERT read_vdp_status_register.end <= $71b1


		db "EOF"
