
; Verify that CTRL was pressed during boot to disable 2nd drive
		FPOS $8019 - Sector2MemoryBase + Sector2FileOffset
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
		FPOS $8170 - Sector2MemoryBase + Sector2FileOffset
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
		jr set_interrupt_handler
