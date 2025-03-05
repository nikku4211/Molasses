;
; Sine lut; 320 entries, 8 fixeds
;

.segment "ABS0DATA"
.align $100
sinlut:

.byte $00, $06, $0C, $12, $19, $1F, $25, $2B
.byte $31, $38, $3E, $44, $4A, $50, $56, $5C
.byte $61, $67, $6D, $73, $78, $7E, $83, $88
.byte $8E, $93, $98, $9D, $A2, $A7, $AB, $B0
.byte $B5, $B9, $BD, $C1, $C5, $C9, $CD, $D1
.byte $D4, $D8, $DB, $DE, $E1, $E4, $E7, $EA
.byte $EC, $EE, $F1, $F3, $F4, $F6, $F8, $F9
.byte $FB, $FC, $FD, $FE, $FE, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FE, $FE, $FD, $FC
.byte $FB, $F9, $F8, $F6, $F4, $F3, $F1, $EE
.byte $EC, $EA, $E7, $E4, $E1, $DE, $DB, $D8
.byte $D4, $D1, $CD, $C9, $C5, $C1, $BD, $B9
.byte $B5, $B0, $AB, $A7, $A2, $9D, $98, $93
.byte $8E, $88, $83, $7E, $78, $73, $6D, $67
.byte $61, $5C, $56, $50, $4A, $44, $3E, $38
.byte $31, $2B, $25, $1F, $19, $12, $0C, $06
.byte $00, $FA, $F4, $EE, $E7, $E1, $DB, $D5
.byte $CF, $C8, $C2, $BC, $B6, $B0, $AA, $A4
.byte $9F, $99, $93, $8D, $88, $82, $7D, $78
.byte $72, $6D, $68, $63, $5E, $59, $55, $50
.byte $4B, $47, $43, $3F, $3B, $37, $33, $2F
.byte $2C, $28, $25, $22, $1F, $1C, $19, $16
.byte $14, $12, $0F, $0D, $0C, $0A, $08, $07
.byte $05, $04, $03, $02, $02, $01, $01, $01
.byte $01, $01, $01, $01, $02, $02, $03, $04
.byte $05, $07, $08, $0A, $0C, $0D, $0F, $12
.byte $14, $16, $19, $1C, $1F, $22, $25, $28
.byte $2C, $2F, $33, $37, $3B, $3F, $43, $47
.byte $4B, $50, $55, $59, $5E, $63, $68, $6D
.byte $72, $78, $7D, $82, $88, $8D, $93, $99
.byte $9F, $A4, $AA, $B0, $B6, $BC, $C2, $C8
.byte $CF, $D5, $DB, $E1, $E7, $EE, $F4, $FA
.byte $00, $06, $0C, $12, $19, $1F, $25, $2B
.byte $31, $38, $3E, $44, $4A, $50, $56, $5C
.byte $61, $67, $6D, $73, $78, $7E, $83, $88
.byte $8E, $93, $98, $9D, $A2, $A7, $AB, $B0
.byte $B5, $B9, $BD, $C1, $C5, $C9, $CD, $D1
.byte $D4, $D8, $DB, $DE, $E1, $E4, $E7, $EA
.byte $EC, $EE, $F1, $F3, $F4, $F6, $F8, $F9
.byte $FB, $FC, $FD, $FE, $FE, $FF, $FF, $FF

.align $100
sinluth:

.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00
.byte $00, $00, $00, $00, $00, $00, $00, $00