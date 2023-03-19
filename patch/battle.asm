
; Convert battle speed(?) parameter and use new sleep routine to wait
		FPOS $a2be - BattleMemoryBase + BattleFileOffset
		add a,a
		add a,a
		add a,a
		add a,a
		ld b,a
		jp sleep
		ASSERT $ <= $a2cc



; Redirect all calls to sleep routine to new sleep routine
		FPOS $aabe - BattleMemoryBase + BattleFileOffset
		jp sleep
		ASSERT $ <= $aac7
