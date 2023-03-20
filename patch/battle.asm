
; Convert battle speed(?) parameter and use new sleep routine to wait
		FPOS $a2be - BattleMemoryBase + BattleFileOffset
		ORG $a2be
		add a,a
		add a,a
		add a,a
		add a,a
		ld b,a
		jp sleep
		ASSERT $ <= $a2cc



; Redirect all calls to sleep routine to new sleep routine
		FPOS $aabe - BattleMemoryBase + BattleFileOffset
		ORG $aabe
		jp sleep
		ASSERT $ <= $aac7
