
; Call music routine directly without all push/pop
		FPOS StartupFileOffset + $fe2
		ORG $bf70
		jp music_play	;$75d4
		ASSERT $ < $bf8b
