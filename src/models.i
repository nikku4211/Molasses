
    /*
     * Generated by Nikku4211's Wavefront to Molasses Converter
     * Nikku4211 - github.com/nikku4211/
     * 
     */

.segment "ABS0DATA"
.align 256
cube_x:
  .word 512
  .word 512
  .word 512
  .word 512
  .word 65024
  .word 65024
  .word 65024
  .word 65024
cube_y:
  .word 1024
  .word 0
  .word 1024
  .word 0
  .word 1024
  .word 0
  .word 1024
  .word 0
cube_z:
  .word 65024
  .word 65024
  .word 512
  .word 512
  .word 65024
  .word 65024
  .word 512
  .word 512

cube_edge1:
  .byte 0,4,6,2
  .byte 3,2,6,7
  .byte 7,6,4,5
  .byte 5,1,3,7
  .byte 1,0,2,3
  .byte 5,4,0,1

cube_edge2:
  .byte 4,6,2,0
  .byte 2,6,7,3
  .byte 6,4,5,7
  .byte 1,3,7,5
  .byte 0,2,3,1
  .byte 4,0,1,5

cube_faces:
  .word 0,256,0
  .word 0,0,256
  .word 65280,0,0
  .word 0,65280,0
  .word 256,0,0
  .word 0,0,65280
