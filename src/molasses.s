.include "libSFX.i"
.include "sinlut.i"
.include "idlut.i"
.include "models.i"

HIROM = 1

;SNESmod audio code
.include "snesmoddoug/snesmod_ca65.asm"

;VRAM destination address
VRAM_MODE7_LOC   = $0000

;Mode 7 center and offset
CENTER_X = 0
CENTER_Y = 0

;camera speed
CAM_SPEED = 64

;initial cam position
INIT_CAM_X = 0 ;((4)<<8)
INIT_CAM_Y = 0 ;((4)<<8)
INIT_CAM_Z = ((256 - 48)<<8)

;rotation amount per axis
INIT_SX = 0
INIT_SY = 0
INIT_SZ = 0

;hardcoded model properties
VERTEX_COUNT = 8
EDGE_COUNT = 24

;toggle music
USE_AUDIO = 1

COSINE_OFFS = 64

; s0.8 by s0.8 fixed point multiplication
; s0.8 fixed point result
; uses a8 and x8
; 
; x is clobbered
; product is stored into a
.macro mult_s0p8_s0p8 cand1, cand2
          
          RW a8i8 ;thanks Not Kieran F
          
          ldx cand2

          lda #0
          stx WRMPYA
          cpx #$80
          bcc :+
            sbc cand1
        : ldx cand1
          stx WRMPYB
          cpx #$80
          bcc :+
            sbc cand2
        : clc
          adc RDMPYH
.endmacro

;this version uses only a and the stack
.macro mult_s0p8_s0p8_stack cand1, cand2
        lda #0
        pha
        lda cand1   ;all i have left is the stack
        sta WRMPYA
        cmp #$80
        bcc :+
          pla
          sbc cand2
          pha
      : lda cand2
        sta WRMPYB
        cmp #$80
        bcc :+
          pla
          sbc cand1
          pha
      : pla
        clc
        adc RDMPYH
.endmacro

; 8.8 by 8.8 fixed point multiplication
; 8.8 fixed point result
; uses a8 and a16
; 
; a16 is where the result is stored
; x16 and y16 are free
.macro mult_8p8_8p8 cand1, cand2, freezpad, cand1h, cand2h
        RW a8
        
        lda cand1 ;p1.l by p2.l
        sta WRMPYA
        lda cand2
        sta WRMPYB
        nop
        nop
        nop
        lda RDMPYH
        sta z:ZPAD+freezpad
        bpl :+
        lda #$ff
        bra :++
      : lda #0
      : sta z:ZPAD+freezpad+1
        
        lda #0
        pha
        lda cand1
        sta WRMPYA
        lda cand2h ;p1.l by p2.h
        sta WRMPYB
        cmp #$80
        bcc :+
          pla
          sbc cand1
          pha
      : pla
        add RDMPYH
        sta z:ZPAD+freezpad+3
        lda RDMPYL
        sta z:ZPAD+freezpad+2
        
        lda #0
        pha
        lda cand1h
        sta WRMPYA
        cmp #$80
        bcc :+
          pla
          sbc cand2
          pha
      : lda cand2 ;p1.h by p2.l
        sta WRMPYB
        nop
        nop
        nop
        pla
        add RDMPYH
        sta z:ZPAD+freezpad+5
        lda RDMPYL
        sta z:ZPAD+freezpad+4
        
        lda cand2h ;p1.h by p2.h
        sta WRMPYB
        nop
        nop
        nop
        RW a16
        lda RDMPYL
        xba
        and #$ff00
        add z:ZPAD+freezpad+4
        adc z:ZPAD+freezpad+2
        adc z:ZPAD+freezpad
.endmacro

; s0.8 by s0.8 fixed point multiplication
; s0.8 fixed point result
; uses a8, x8, and y8
; 
; x, and y are clobbered
; product is stored into a
.macro mult_s8p8_s8p8_trig cand1, cand2, cos1, cos2
          RW a8i8 ;thanks Not Kieran F

          ldx cand1
          ldy sinlut+cos1,x
          ldx cand2
          lda sinlut+cos2,x
          tax

          lda #0
          stx WRMPYA
          cpx #$80
          bcc :+
            sbc idlut,y
        : sty WRMPYB
          cpy #$80
          bcc :+
            sbc idlut,x
        : clc
          adc RDMPYH
.endmacro

; 8.8 by 0.8 fixed point multiplication
; 8.8 fixed point result
; uses a8 and a16
; 
; a16 is where the result is stored
; index is free
.macro mult_8p8_s0p8_trig cand1, cand2, freezpad, cand2h
        RW a8i8
        
        mult_s0p8_s0p8_stack {cand1}, {cand2}
        sta z:ZPAD+freezpad
        bmi :+  ;gotta sign extend
        lda #$00
        bra :++
        : lda #$ff
        : sta z:ZPAD+freezpad+1
        
        lda #0
        pha
        lda cand1
        sta WRMPYA
        cmp #$80
        bcc :+
          pla
          sbc cand2h
          pha
      : lda cand2h ;p1.l by p2.h
        sta WRMPYB
        cmp #$80
        bcc :+
          pla
          sbc cand1
          pha
      : pla
        add RDMPYH
        sta z:ZPAD+freezpad+3
        lda RDMPYL
        sta z:ZPAD+freezpad+2
        
        lda cand1
        cmp #$80
        bcc :+
        lda #$ff
        sta WRMPYA
        lda cand2h ;p1.h by p2.h
        sta WRMPYB
        nop
        nop
        nop
        RW a16i16
        lda RDMPYL
        xba
        and #$00ff
        bra :++
      : RW_forced a16i16
        lda #0
      : add z:ZPAD+freezpad+2
        adc z:ZPAD+freezpad
.endmacro

;bresenham line macro (low part)
;x16 is clobbered
;a8 and a16 are also used
.macro hamline_low x0, y0, x1, y1, col, freezpad
.scope
        RW_forced a8i16
        lda x0 ;x0
        sta z:ZPAD+freezpad
        lda x1 ;x1
        sta z:ZPAD+freezpad+1
        lda y0 ;y0
        sta z:ZPAD+freezpad+2
        lda y1 ;y1
        sta z:ZPAD+freezpad+3
        
        lda z:ZPAD+freezpad+1
        sub z:ZPAD+freezpad
        sta ham_dx ;dx = x1 - x0
      
        lda z:ZPAD+freezpad+3
        sub z:ZPAD+freezpad+2
        sta ham_dy ;dy = y1 - y0
        
        lda #1
        sta ham_yi ;yi = 1
        
        lda ham_dy
        bpl :+ ;if dy < 0
        lda #$ff
        sta ham_yi ;yi = -1
        lda ham_dy 
        neg ;dy = -dy
      : sta ham_dy
      
        asl
        sub ham_dx
        sta ham_dee ;D = (2*dy) - dx
      
        lda z:ZPAD+freezpad+2
        sta ham_y
        lda z:ZPAD+freezpad
        sta ham_x
forloop:
        RW a16i16
        lda ham_y-1
        and #$7f00
        lsr
        ora ham_x
        tax
        RW a8
        lda col
        sta f:pseudobitmap,x ; plot(x0, y0)
        
        lda ham_dee ;if D > 0
        bmi :+
        lda ham_y
        add ham_yi ; Y += yi
        sta ham_y
        lda ham_dy
        sub ham_dx
        asl
        add ham_dee
        sta ham_dee ; D += 2 * (dy - dx)
        bra :++
      : lda ham_dy ; else
        asl
        add ham_dee
        sta ham_dee ; D += 2*dy
      : lda ham_x
        inc
        sta ham_x
        cmp z:ZPAD+freezpad+1
        bne forloop
nomoreloop:
.endscope
.endmacro

;bresenham line macro (high part)
;x16 is clobbered
;a8 and a16 are also used
.macro hamline_high x0, y0, x1, y1, col, freezpad
.scope
        RW_forced a8i16
        lda x0 ;x0
        sta z:ZPAD+freezpad
        lda x1 ;x1
        sta z:ZPAD+freezpad+1
        lda y0 ;y0
        sta z:ZPAD+freezpad+2
        lda y1 ;y1
        sta z:ZPAD+freezpad+3
        
        lda z:ZPAD+freezpad+1
        sub z:ZPAD+freezpad
        sta ham_dx ;dx = x1 - x0
      
        lda z:ZPAD+freezpad+3
        sub z:ZPAD+freezpad+2
        sta ham_dy ;dy = y1 - y0
        
        lda #1
        sta ham_xi ;xi = 1
        
        lda ham_dx
        bpl :+ ;if dx < 0
        lda #$ff
        sta ham_xi ;xi = -1
        lda ham_dx 
        neg ;xy = -dx
      : sta ham_dx
      
        asl
        sub ham_dy
        sta ham_dee ;D = (2*dx) - dy
      
        lda z:ZPAD+freezpad+2
        sta ham_y
        lda z:ZPAD+freezpad
        sta ham_x
forloop:
        RW a16i16
        lda ham_y-1
        and #$7f00
        lsr
        ora ham_x
        tax
        RW a8
        lda col
        sta f:pseudobitmap,x ; plot(x0, y0)
        
        lda ham_dee ;if D > 0
        bmi :+
        lda ham_x
        add ham_xi ; x += xi
        sta ham_x
        lda ham_dx
        sub ham_dy
        asl
        add ham_dee
        sta ham_dee ; D += 2 * (dx - dy)
        bra :++
      : lda ham_dx ; else
        asl
        add ham_dee
        sta ham_dee ; D += 2*dx
      : lda ham_y
        inc
        sta ham_y
        cmp z:ZPAD+freezpad+3
        bne forloop
nomoreloop:
.endscope
.endmacro

;bresenham line macro (general)
;x16 is clobbered
;a8 and a16 are also used
;x0, x1, y0, and y1 must be 8bit and leave the sign bit unused
.macro hamline x0, y0, x1, y1, col, freezpad
.scope
        RW_forced a8i16
        
        lda x1
        sub x0
        bpl :+
        neg
      : sta z:ZPAD+freezpad+1 ;abs(x1 - x0)
        
        lda y1
        sub y0
        bpl :+
        neg
      : sta z:ZPAD+freezpad ;abs(y1 - y0)
      
        cmp z:ZPAD+freezpad+1
        bcc :+ ;if abs(y1 - y0) < abs(x1 - x0)
        jmp if_abs_greater
       :
        
        lda x0
        cmp x1
        beq :+
        bcs if_x0_greater
      : jmp if_x0_lesser ;if x0 > x1
    if_x0_greater:
        hamline_low {x1}, {y1}, {x0}, {y0}, col, freezpad+2
        jmp end_if_abs
    if_x0_lesser:
        hamline_low {x0}, {y0}, {x1}, {y1}, col, freezpad+2
        jmp end_if_abs
if_abs_greater: ;else
        lda y0
        cmp y1
        beq :+
        bcs if_y0_greater
      : jmp if_y0_lesser ;if y0 > y1
    if_y0_greater:
        hamline_high {x1}, {y1}, {x0}, {y0}, col, freezpad+2
        jmp end_if_abs
    if_y0_lesser:
        hamline_high {x0}, {y0}, {x1}, {y1}, col, freezpad+2
end_if_abs: ;end if
.endscope
.endmacro

Main:

        ;libSFX calls Main after CPU/PPU registers, memory and interrupt handlers are initialized.
        ;load a program to the s-apu and run it
        .if ::USE_AUDIO
          RW a8i16
          jsr spcBoot ;copy the spc program
        
          ;a = bank #
          lda #^game_music
          jsr spcSetBank
          
          ;x = module_id
          ldx #0
          jsr spcLoad ; load the module

          ;a = bank #
          lda #^sfx_bank
          jsr spcSetBank
          
          jsr spcProcess

          ;a = starting position (pattern number)
          lda #0
          jsr spcPlay
          
          lda #$7f ;0-255, 7f is half volume 
          jsr spcSetModuleVolume
          
          jsr spcProcess
        .endif
  
        ;Set color 0
        CGRAM_memcpy 0, m7pbpalette, sizeof_m7pbpalette
        WRAM_memset pseudobitmap, 16384, $00

        RW a8i16
        
        ldx #(60+(128*56))
        lda #$44
        sta f:pseudobitmap,x
        
        lda #$00
        ldx #$0000
        
        RW a8i8
        
        VRAM_memcpy VRAM_MODE7_LOC, m7pbtiles, sizeof_m7pbtiles, $80, 0, $19       ;Transfer tiles to odd VRAM addresses
        VRAM_memcpy VRAM_MODE7_LOC, pseudobitmap, 16384, 0, 0, $18       ;Transfer map to even VRAM addresses
        
        ;Set up screen mode
        lda     #bgmode(BG_MODE_7, BG3_PRIO_NORMAL, BG_SIZE_8X8, BG_SIZE_8X8, BG_SIZE_8X8, BG_SIZE_8X8)
        sta     BGMODE
        lda     #tm(ON, OFF, OFF, OFF, OFF)
        sta     TM
        
        ;init mode 7 scroll and scale parameters
        stz BG1HOFS
        stz BG1HOFS
        stz BG1VOFS
        stz BG1VOFS
        
        lda     #<CENTER_X
        sta     M7X
        lda     #>CENTER_X
        sta     M7X
        lda     #<CENTER_Y
        sta     M7Y
        lda     #>CENTER_Y
        sta     M7Y
        
        lda #$04
        stz M7A
        sta M7A
        lda #$02
        stz M7D
        sta M7D
        
        stz M7SEL
        stz M7SEL

        ;Set VBlank handler
        VBL_set VBL

        ;Turn on screen
        ;The vblank interrupt handler will copy the value in SFX_inidisp to INIDISP ($2100)
        lda     #inidisp(ON, DISP_BRIGHTNESS_MAX)
        sta     SFX_inidisp

        RW a8i16
        
        ;manually copy pseudobitmap in ROM to pseudobitmap in RAM
        ; ldx #16383
; :       lda f:m7testpbm,x
        ; sta f:pseudobitmap,x
        ; dex
        ; bne :-
        
        lda #1
        sta z:vramsplit
        stz z:threeddoneflag

        ;Turn on vblank interrupt
        VBL_on

        ldx #INIT_CAM_X
        stx z:camx
        ldx #INIT_CAM_Y
        stx z:camy
        ldx #INIT_CAM_Z
        stx z:camz
:       
        
        lda #INIT_SX ;initialise rotations
        sta z:matrix_sx
        lda #INIT_SY
        sta z:matrix_sy
        lda #INIT_SZ
        sta z:matrix_sz
        
        lda #$81
        pha
        plb
        
polyrotation:
polyrotationsetup:
        RW i8
; x-
        ldx z:matrix_sx ;angle A
        ldy z:matrix_sy ;angle B
        
        mult_8p8_8p8 {sinlut+COSINE_OFFS,x}, {sinlut+COSINE_OFFS,y}, 6, {sinluth+COSINE_OFFS,x}, {sinluth+COSINE_OFFS,y} ;xx = [cos(A)cos(B)]
        sta matrix_xx
      
        mult_8p8_8p8 {sinlut,x}, {sinlut+COSINE_OFFS,y}, 6, {sinluth,x}, {sinluth+COSINE_OFFS,y} ;xy = [sin(A)cos(B)]
        sta matrix_xy
      
        ;xz = [sin(B)]
        RW a8
        lda sinlut,y
        sta matrix_xz
        lda sinluth,y
        sta matrix_xz+1
        
; y-
        ldy z:matrix_sz ;angle C
        
        mult_8p8_8p8 {sinlut,x}, {sinlut+COSINE_OFFS,y}, 6, {sinluth,x}, {sinluth+COSINE_OFFS,y} ;yx = [sin(A)cos(C)
        sta z:ZPAD
      
        ldy z:matrix_sy
        mult_8p8_8p8 {sinlut+COSINE_OFFS,x}, {sinlut,y}, 6, {sinluth+COSINE_OFFS,x}, {sinluth,y}     ;+ cos(A)sin(B)sin(C)]
        sta z:ZPAD+2
        
        ldy z:matrix_sz
        mult_8p8_8p8 z:ZPAD+2, {sinlut,y}, 6, z:ZPAD+3, {sinluth,y}
        add z:ZPAD
        sta matrix_yx
        
        mult_8p8_8p8 {sinlut+COSINE_OFFS,x}, {sinlut+COSINE_OFFS,y}, 6, {sinluth+COSINE_OFFS,x}, {sinluth+COSINE_OFFS,y} ;yy = [-cos(A)cos(C)
        sta z:ZPAD
        
        ldy z:matrix_sy                                                                                  ;+ sin(A)sin(B)sin(C)]
        mult_8p8_8p8 {sinlut,x}, {sinlut,y}, 6, {sinluth,x}, {sinluth,y} 
        sta z:ZPAD+2
        
        ldy z:matrix_sz
        mult_8p8_8p8 z:ZPAD+2, {sinlut,y}, 6, z:ZPAD+3, {sinluth,y}
        sub z:ZPAD
        sta matrix_yy
        
        ldx z:matrix_sy
        mult_8p8_8p8 {sinlut+COSINE_OFFS,x}, {sinlut,y}, 6, {sinluth+COSINE_OFFS,x}, {sinluth,y}    ;yz = [-cos(B)sin(C)]
        neg
        sta matrix_yz
        
; z-
        ldx z:matrix_sx
        mult_8p8_8p8 {sinlut,x}, {sinlut,y}, 6, {sinluth,x}, {sinluth,y} ;zx = [sin(A)sin(C)
        sta z:ZPAD
      
        ldy z:matrix_sy
        mult_8p8_8p8 {sinlut+COSINE_OFFS,x}, {sinlut,y}, 6, {sinluth+COSINE_OFFS,x}, {sinluth,y}      ;- cos(A)sin(B)cos(C)]
        sta z:ZPAD+2
        
        ldy z:matrix_sz
        mult_8p8_8p8 z:ZPAD+2, {sinlut+COSINE_OFFS,y}, 6, z:ZPAD+3, {sinluth+COSINE_OFFS,y}
        sta z:ZPAD+2
        
        lda z:ZPAD
        sub z:ZPAD+2
        sta matrix_zx
      
        mult_8p8_8p8 {sinlut+COSINE_OFFS,x}, {sinlut,y}, 6, {sinluth+COSINE_OFFS,x}, {sinluth,y}    ;zy = [-cos(A)sin(C)
        neg
        sta z:ZPAD
      
        ldy z:matrix_sy
        mult_8p8_8p8 {sinlut,x}, {sinlut,y}, 6, {sinluth,x}, {sinluth,y}     ;- sin(A)sin(B)cos(C)]
        sta z:ZPAD+2
        
        ldy z:matrix_sz
        mult_8p8_8p8 z:ZPAD+2, {sinlut+COSINE_OFFS,y}, 6, z:ZPAD+3, {sinluth+COSINE_OFFS,y}
        neg
        add z:ZPAD
        sta matrix_zy
        
        ldx z:matrix_sy
        mult_8p8_8p8 {sinlut+COSINE_OFFS,x}, {sinlut+COSINE_OFFS,y}, 6, {sinluth+COSINE_OFFS,x}, {sinluth+COSINE_OFFS,y}  ;zz = [cos(B)cos(C)]
        sta matrix_zz

; ?x*?y
        mult_8p8_8p8 matrix_xx, matrix_xy, 6, matrix_xx+1, matrix_xy+1
        sta matrix_xx_xy
        
        mult_8p8_8p8 matrix_yx, matrix_yy, 6, matrix_yx+1, matrix_yy+1
        sta matrix_yx_yy
        
        mult_8p8_8p8 matrix_zx, matrix_zy, 6, matrix_zx+1, matrix_zy+1
        sta matrix_zx_zy
        
        RW i16
        ldy #0
uopolyrotationloop:
        ;rember pemdas:
        ;
        ;parentheses first
        ;multiplication next
        ;then both adding and subtracting together
        ;
        mult_8p8_8p8 {a:cube_x,y}, {a:cube_y,y}, 0, {a:cube_x+1,y}, {a:cube_y+1,y} ;but before all that, let's precalc x*y
        sta matrix_x_m_y ;not to be confused with matrix_xy

; x'   
        ;okay, now Please Excuse My Dear Aunt Sally
        ;(xx + y)(xy + x) + z*xz - (xx_xy + x_y)
        lda matrix_xx ;(xx + y)
        add a:cube_y,y
        sta z:ZPAD
        lda matrix_xy ;(xy + x)
        add a:cube_x,y
        sta z:ZPAD+2
        lda matrix_xx_xy ;(xx_xy + x_y)
        add matrix_x_m_y
        sta z:ZPAD+4
        
        mult_8p8_8p8 {a:cube_z,y}, matrix_xz, 6, {a:cube_z+1,y}, matrix_xz+1 ;z*xz
        sta matrix_z_xz
        
        mult_8p8_8p8 z:ZPAD, z:ZPAD+2, 6, z:ZPAD+1, z:ZPAD+3 ;(xx + y)(xy + x)
        sta z:ZPAD+12
        
        lda z:ZPAD+12 ;(xx + y)(xy + x) + z*xz - (xx_xy + x_y)
        add matrix_z_xz
        sub z:ZPAD+4
        sta matrix_pointx,y
        
; y'
        ;(yx + y)(yy + x) + z*yz - (yx_yy + x_y)
        lda matrix_yx ;(yx + y)
        add a:cube_y,y
        sta z:ZPAD
        lda matrix_yy ;(yy + x)
        add a:cube_x,y
        sta z:ZPAD+2
        lda matrix_yx_yy ;(yx_yy + x_y)
        add matrix_x_m_y
        sta z:ZPAD+4
        
        mult_8p8_8p8 {a:cube_z,y}, matrix_yz, 6, {a:cube_z+1,y}, matrix_yz+1  ;z*yz
        sta matrix_z_yz
        
        mult_8p8_8p8 z:ZPAD, z:ZPAD+2, 6, z:ZPAD+1, z:ZPAD+3 ;(yx + y)(yy + x)
        sta z:ZPAD+12
        
        lda z:ZPAD+12 ;(yx + y)(yy + x) + z*yz - (yx_yy + x_y)
        add matrix_z_yz
        sub z:ZPAD+4
        sta matrix_pointy,y
        
; z'
        ;(zx + y)(zy + x) + z*zz - (zx_zy + x_y)
        lda matrix_zx ;(zx + y)
        add a:cube_y,y
        sta z:ZPAD
        lda matrix_zy ;(zy + x)
        add a:cube_x,y
        sta z:ZPAD+2
        lda matrix_zx_zy ;(zx_zy + x_y)
        add matrix_x_m_y
        sta z:ZPAD+4
        
        mult_8p8_8p8 {a:cube_z,y}, matrix_zz, 6, {a:cube_z+1,y}, matrix_zz+1 ;z*zz
        sta matrix_z_zz
        
        mult_8p8_8p8 z:ZPAD, z:ZPAD+2, 6, z:ZPAD+1, z:ZPAD+3 ;(zx + y)(zy + x)
        sta z:ZPAD+12
        
        lda z:ZPAD+12 ;(zx + y)(zy + x) + z*zz - (zx_zy + x_y)
        add matrix_z_zz
        sub z:ZPAD+4
        sta matrix_pointz,y
        
donepolyrotation:
        iny
        iny
        cpy #(VERTEX_COUNT * 2)
        beq polyprojection
        jmp uopolyrotationloop
        
polyprojection:
        RW a8i16
        ldy #0
projectionloop:
@xpointpro:
        RW a16i16
        stz z:nopoint
        stz z:invertpointx
        ; get cube x points and divide by z
        lda a:matrix_pointx,y
        sub z:camx
        cmp #$8000
        bcc @notnegativex
        sta z:invertpointx
        neg
@notnegativex:
        sta WRDIVL
        lda a:matrix_pointz,y
        sub z:camz
        xba
        RW a8i16
        sta WRDIVB
.repeat 7
        nop
.endrepeat

        RW a16i16
        lda RDDIVL
        ldx z:invertpointx
        beq :+
        neg
:
        lsr
        add #$0040    ;centre the point
        and #$7fff
        cmp #$0080  
        and #$007f
        sta a:pointxword,y
        bcs @pointoffscreen ;if point offscreen, don't draw
@ypointpro:
        ; get cube y points and divide by z
        stz z:invertpointy
        lda a:matrix_pointy,y
        sub z:camy
        cmp #$8000
        bcc @notnegativey
        sta z:invertpointy
        neg
@notnegativey:
        sta WRDIVL
        lda a:matrix_pointz,y
        sub z:camz
        xba
        RW a8i16
        sta WRDIVB
.repeat 7
        nop
.endrepeat
        RW a16i16
        lda RDDIVL
        ldx z:invertpointy
        beq :+
        neg
:
        lsr
        add #$0040
        and #$7fff
        lsr
        cmp #$0080
        sta a:pointyword,y
        bcc @donepointpro ;if point offscreen, don't draw
@pointoffscreen:
        lda #$003f
        sta a:pointyword,y
        lda #1
        sta z:nopoint
@donepointpro:
        stz z:invertpointx
        stz z:invertpointy
        
        lda a:oldpointyword,y
        and #$003f
        xba
        lsr
        ora a:oldpointxword,y
        and #$1fff
        tax
        
        RW a8i16
        lda #$00
        sta f:pseudobitmap,x
        
        RW a16i16
        lda z:nopoint
        bne @nextloop
        
        lda a:pointxword,y
        
        lda a:pointyword,y
        and #$003f
        xba
        lsr
        ora a:pointxword,y
        and #$1fff
        tax
        
        RW a8i16
        lda #$f0
        sta f:pseudobitmap,x
@nextloop:      
        iny
        iny
        cpy #(VERTEX_COUNT*2)
        beq drawedge
        jmp projectionloop
      : jmp updatepointsstart
        
drawedge:
        RW i16
        ldy #0

edgeloop:
        RW_forced a16i16
        lda a:cube_edge1,y ;erase old line first
        and #$00ff
        asl
        tax
        lda a:oldpointxword,x
        sta z:ZPAD
        lda a:oldpointyword,x
        sta z:ZPAD+2
        
        lda a:cube_edge2,y
        and #$00ff
        asl
        tax
        hamline z:ZPAD, z:ZPAD+2, {a:oldpointxword,x}, {a:oldpointyword,x}, #$00, 4

        RW_forced a16i16
        lda a:cube_edge1,y
        and #$00ff
        asl
        tax
        lda a:pointxword,x
        sta z:ZPAD
        lda a:pointyword,x
        sta z:ZPAD+2
        
        lda a:cube_edge2,y
        and #$00ff
        asl
        tax
        hamline z:ZPAD, z:ZPAD+2, {a:pointxword,x}, {a:pointyword,x}, #$20, 4
                
@nextloop:
        iny
        cpy #EDGE_COUNT
        beq updatepointsstart
        jmp edgeloop
        
updatepointsstart: ldy #0
updatepoints:
        RW a16i16
        lda a:pointxword,y
        sta a:oldpointxword,y
        lda a:pointyword,y
        sta a:oldpointyword,y
@nextloop2:
        iny
        iny
        cpy #(VERTEX_COUNT*2)
        bne updatepoints

        RW a8i16
threeddone:
        lda #1
        sta z:threeddoneflag
        
        RW a8i16
forever:
        wai
        lda z:threeddoneflag
        bne forever
        jmp polyrotation
        
;-

VBL:
        RW a8i16
        lda z:vrampage ;multiply vrampage's second bit by 4096
        and #%00000011
        asl
        asl
        asl
        asl
        xba
        tay
        
        lda z:vramsplit
        beq lastvblankinit
        cmp #1
        beq middlevblankinit
        VRAM_memcpy VRAM_MODE7_LOC, pseudobitmap, 4096, 0, 0, $18       ;Transfer first third of map to even VRAM addresses
        lda z:vramsplit
        dec
        sta z:vramsplit
        bra donevblankinit
  lastvblankinit:
        VRAM_memcpy y, (pseudobitmap+4096), 3072, 0, 0, $18       ;Transfer last third of map to even VRAM addresses
        lda #1  ;setup vramsplit for the next trio of frames
        sta z:vramsplit
        stz z:threeddoneflag
        lda z:vrampage
        and #%00000010
        lsr
        stz BG1VOFS
        sta BG1VOFS
        ;inc z:matrix_sx
        inc z:matrix_sy
        ;inc z:matrix_sz
        bra donevblankinit
  middlevblankinit:
        VRAM_memcpy y, (pseudobitmap), 4096, 0, 0, $18       ;Transfer middle third of map to even VRAM addresses
        lda z:vramsplit
        dec
        sta z:vramsplit
  donevblankinit:
        inc z:vrampage
        RW a16i16
readright:
        lda SFX_joy1cont
        and #JOY_RIGHT
        beq readleft
moveright:
        lda z:camx
        add #CAM_SPEED
        sta z:camx
        
readleft:
        lda SFX_joy1cont
        and #JOY_LEFT
        beq readel
moveleft:
        lda z:camx
        sub #CAM_SPEED
        sta z:camx

readel:
        lda SFX_joy1cont
        and #JOY_L
        beq readare
moveup:
        lda z:camy
        sub #CAM_SPEED
        sta z:camy
        
readare:
        lda SFX_joy1cont
        and #JOY_R
        beq readup
movedown:
        lda z:camy
        add #CAM_SPEED
        sta z:camy
        
readup:
        lda SFX_joy1cont
        and #JOY_UP
        beq readdown
moveforward:
        lda z:camz
        add #CAM_SPEED
        sta z:camz

readdown:
        lda SFX_joy1cont
        and #JOY_DOWN
        beq :+
movebackward:
        lda z:camz
        sub #CAM_SPEED
        sta z:camz
:
        RW a8i16
        rtl

.segment "RODATA"
incbin m7pbpalette,        "data/chunktestpalette.png.palette"
incbin m7pbtiles,          "data/chunktestpalette.png.tiles"

;.segment "ROM1"
;incbin m7testpbm, "data/chunktest.png.pbm"

.segment "ROM2"
.align $100
incbin game_music, "data/game_music.bank"
incbin sfx_bank, "data/sfxbank.bank"
SNESMOD_SPC:
incbin snesmod_spc, "snesmoddoug/snesmod_driver.bin"
SNESMOD_SPC_END:

.assert .loword(game_music) = 0, lderror

.segment "HIRAM"
pseudobitmap:
.align $100
.res 8192 ;formerly 16384

.segment "ZEROPAGE"
threeddoneflag: .res 1
vramsplit: .res 1
vrampage: .res 1
camx: .res 2
camy: .res 2
camz: .res 2
invertpointx: .res 2
invertpointy: .res 2
invertpointz: .res 2
nopoint: .res 2
matrix_sx: .res 1
matrix_sy: .res 1
matrix_sz: .res 1

.segment "LORAM"
pointxword: .res (VERTEX_COUNT * 2)
pointyword: .res (VERTEX_COUNT * 2)
oldpointxword: .res (VERTEX_COUNT * 2)
oldpointyword: .res (VERTEX_COUNT * 2)

matrix_xx: .res 2
matrix_xy: .res 2
matrix_xz: .res 2

matrix_yx: .res 2
matrix_yy: .res 2
matrix_yz: .res 2

matrix_zx: .res 2
matrix_zy: .res 2
matrix_zz: .res 2

matrix_xx_xy: .res 2
matrix_yx_yy: .res 2
matrix_zx_zy: .res 2

matrix_x_m_y: .res 2
matrix_z_xz: .res 2
matrix_z_yz: .res 2
matrix_z_zz: .res 2

matrix_pointx: .res (VERTEX_COUNT * 2)
matrix_pointy: .res (VERTEX_COUNT * 2)
matrix_pointz: .res (VERTEX_COUNT * 2)

ham_dee: .res 1
ham_dx: .res 1
ham_dy: .res 1
ham_y: .res 2
ham_x: .res 2
ham_yi: .res 1
ham_xi: .res 1

matrix_edge: .res EDGE_COUNT
