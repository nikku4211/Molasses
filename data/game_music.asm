;************************************************
; snesmod soundbank data                        *
; total size:      41220 bytes                  *
;************************************************

	.global __SOUNDBANK__
	.segment "SOUNDBANK" ; need dedicated bank(s)

__SOUNDBANK__:
	.incbin "game_music.bank"
