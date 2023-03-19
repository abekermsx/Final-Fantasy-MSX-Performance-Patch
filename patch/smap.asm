
; Faster sprites copy routine
		FPOS $81a3 - SmapMemoryBase + SmapFileOffset
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
		FPOS $8308 - SmapMemoryBase + SmapFileOffset
		ORG $8308
		jp fast_ldir
		ASSERT $ <= $830b
		
		

; Use fast otir routine to copy sprite colors
		FPOS $8389 - SmapMemoryBase + SmapFileOffset
		ORG $8389
		call fast_otir_de
		ei
		ret
		ASSERT $ <= $8392
