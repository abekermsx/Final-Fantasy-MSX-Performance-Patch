
; Use read_key_helper to read from keyboard correctly
		FPOS $89a4 - StartUpMemoryBase + StartupFileOffset
		ORG $89a4
		call chget_helper

		
; Call music routine directly without all push/pop
		FPOS StartupFileOffset + $fe2
		ORG $bf70
		jp music_play	;$75d4
		ASSERT $ < $bf8b
