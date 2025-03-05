.segment "ABS0DATA"
.align 256
cube_x:
; point x values
.word $fc00,$fc00,$0400,$0400
.word $fc00,$0400,$0400,$fc00

cube_y:
; point y values
.word $fc00,$0400,$fc00,$0400
.word $0400,$fc00,$0400,$fc00

cube_z:
; point z values
.word $fc00,$fc00,$fc00,$fc00
.word $0400,$0400,$0400,$0400

cube_edge1:
; first point per edge
.byte 0,0,1,2,3,3,4,6
.byte 7,5,4,2

cube_edge2:
; second point per edge
.byte 1,2,2,3,6,4,7,7
.byte 5,1,1,6