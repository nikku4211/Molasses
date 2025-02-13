.include "libSFX.i"
.include "sinlut.i"
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
INIT_CAM_Z = ((256 - 16)<<8)

;rotation amount per axis
INIT_SX = 0
INIT_SY = 0
INIT_SZ = 0

;toggle music
USE_AUDIO = 1

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
        lda #$81
        pha
        plb

        lda #INIT_SX ;initialise rotations
        sta z:matrix_sx
        lda #INIT_SY
        sta z:matrix_sy
        lda #INIT_SZ
        sta z:matrix_sz
        
polyrotation:
; x-
        RW a16i8
        ldx z:matrix_sx     ;xx = [cos(A)cos(B)]
        ldy sinlut+32,x
        sty WRMPYA
        ldx z:matrix_sy
        ldy sinlut+32,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        sta matrix_xx
        
        
        ;x has sy
        ldy sinlut+32,x
        sty WRMPYA
        ldx z:matrix_sx     ;xy = [sin(A)cos(B)]
        ldy sinlut,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        sta matrix_xy
        
        ldx z:matrix_sy      ;xz = [sin(B)]
        lda sinlut,x
        and #$00ff
        sta matrix_xz
        
; y-
        ldx z:matrix_sx
        ldy sinlut,x
        sty WRMPYA
        ldx z:matrix_sz     ;yx = [sin(A)cos(C)
        ldy sinlut+32,x
        sty WRMPYB
        ldx z:matrix_sx
        nop
        lda RDMPYL
        sta z:ZPAD
        ldy sinlut+32,x
        sty WRMPYA
        ldx z:matrix_sy     ;+ cos(A)sin(B)sin(C)]
        ldy sinlut,x
        sty WRMPYB
        nop
        ldx z:matrix_sz
        ldy RDMPYL
        sty WRMPYA
        ldy sinlut,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        add z:ZPAD
        sta matrix_yx
        
        ldx z:matrix_sx
        ldy sinlut+32,x
        sty WRMPYA
        ldx z:matrix_sz     ;yy = [-cos(A)cos(C)
        ldy sinlut+32,x
        sty WRMPYB
        ldx z:matrix_sx
        nop
        lda RDMPYL
        sta z:ZPAD
        ldy sinlut,x
        sty WRMPYA
        ldx z:matrix_sy     ;+ sin(A)sin(B)sin(C)]
        ldy sinlut,x
        sty WRMPYB
        ldx z:matrix_sz
        ldy RDMPYL
        sty WRMPYA
        ldy sinlut,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        sub z:ZPAD
        sta matrix_yy
        
        ;x has sz
        ldy sinlut,x
        sty WRMPYA
        ldx z:matrix_sy     ;yz = [-cos(B)sin(C)]
        ldy sinlut+32,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        neg
        sta matrix_yz
        
; z-
        ldx z:matrix_sx
        ldy sinlut+32,x
        sty WRMPYA
        ldx z:matrix_sy     ;zx = [sin(A)sin(C) - cos(A)sin(B)cos(C)]
        ldy sinlut,x
        sty WRMPYB
        nop
        ldx z:matrix_sz
        ldy RDMPYL
        sty WRMPYA
        ldy sinlut+32,x
        sty WRMPYB
        ldx z:matrix_sz
        nop
        lda RDMPYL
        sta z:ZPAD
        ldy sinlut,x
        sty WRMPYA
        ldx z:matrix_sz
        ldy sinlut,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        sub z:ZPAD
        sta matrix_zx
        
        ldx z:matrix_sx
        ldy sinlut+32,x
        sty WRMPYA
        ldx z:matrix_sz     ;zy = [-cos(A)sin(C)
        ldy sinlut,x
        sty WRMPYB
        ldx z:matrix_sx
        nop
        lda RDMPYL
        sta z:ZPAD
        ldy sinlut,x
        sty WRMPYA
        ldx z:matrix_sy     ;- sin(A)sin(B)cos(C)]
        ldy sinlut,x
        sty WRMPYB
        nop
        ldx z:matrix_sx
        ldy RDMPYL
        sty WRMPYA
        ldy sinlut+64,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        neg
        sub z:ZPAD
        sta matrix_zy

        ldx z:matrix_sy     ;zz = [cos(B)cos(C)]
        ldy sinlut+32,x
        sty WRMPYA
        ldx z:matrix_sz
        ldy sinlut+32,x
        sty WRMPYB
        nop
        nop
        nop
        lda RDMPYL
        sta matrix_zz

; ?x*?y
        RW a8i16
        lda matrix_xx ;xx_xy = xx*xy
        sta WRMPYA
        lda matrix_xy
        sta WRMPYB
        nop
        lda matrix_xy+1
        ldx RDMPYL
        stx z:ZPAD
        sta WRMPYB
        nop
        lda matrix_xx+1
        ldy RDMPYL
        sty z:ZPAD+2
        sta WRMPYA
        lda matrix_xy
        sta WRMPYB
        RW a16i8
        lda z:ZPAD
        add z:ZPAD+2
        add RDMPYL
        sta matrix_xx_xy
        
        RW a8i16
        lda matrix_yx ;yx_yy = yx*yy
        sta WRMPYA
        lda matrix_yy
        sta WRMPYB
        nop
        lda matrix_yy+1
        ldx RDMPYL
        stx z:ZPAD
        sta WRMPYB
        nop
        lda matrix_yx+1
        ldy RDMPYL
        sty z:ZPAD+2
        sta WRMPYA
        lda matrix_yy
        sta WRMPYB
        RW a16i8
        lda z:ZPAD
        add z:ZPAD+2
        add RDMPYL
        sta matrix_yx_yy
        
        RW a8i16
        lda matrix_zx ;zx_zy = zx*zy
        sta WRMPYA
        lda matrix_zy
        sta WRMPYB
        nop
        lda matrix_zy+1
        ldx RDMPYL
        stx z:ZPAD
        sta WRMPYB
        nop
        lda matrix_zx+1
        ldx RDMPYL
        sta WRMPYA
        lda matrix_zy
        sta WRMPYB
        RW a16i16
        txa
        add z:ZPAD
        add RDMPYL
        sta matrix_zx_zy
        
        ldy #0
polyrotationloop:
        ;rember pemdas:
        ;
        ;parentheses first
        ;multiplication next
        ;then both adding and subtracting together
        ;
        RW_forced a8i16
        lda a:cube_x,y ;but before all that, let's precalc x*y
        sta WRMPYA
        lda a:cube_y,y
        sta WRMPYB
        nop
        lda a:cube_y+1,y
        ldx RDMPYL
        stx z:ZPAD
        sta WRMPYB
        nop
        lda a:cube_x+1,y
        ldx RDMPYL
        stx z:ZPAD+2
        sta WRMPYA
        lda a:cube_y,y
        sta WRMPYB
        RW a16i16
        lda z:ZPAD
        add z:ZPAD+2
        add RDMPYL
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
        
        RW a8i16
        lda a:cube_z,y ;z*xz
        sta WRMPYA
        lda matrix_xz
        sta WRMPYB
        nop
        lda a:cube_z+1,y
        ldx RDMPYL
        stx z:ZPAD+6
        sta WRMPYB
        nop
        lda matrix_xz+1
        ldx RDMPYL
        sta WRMPYA
        lda a:cube_z,y
        sta WRMPYB
        RW a16i16
        txa
        add z:ZPAD+6
        add RDMPYL
        sta matrix_z_xz
        
        RW a8i16
        lda z:ZPAD ;(xx + y)(xy + x)
        sta WRMPYA
        lda z:ZPAD+2
        sta WRMPYB
        nop
        lda z:ZPAD+1
        ldx RDMPYL
        stx z:ZPAD+6
        sta WRMPYB
        nop
        lda z:ZPAD+3
        ldx RDMPYL
        sta WRMPYA
        lda z:ZPAD
        sta WRMPYB
        RW a16i16
        txa
        add z:ZPAD+6
        add RDMPYL
        sta z:ZPAD+8
        
        lda z:ZPAD+8 ;(xx + y)(xy + x) + z*xz - (xx_xy + x_y)
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
        
        RW a8i16
        lda a:cube_z,y ;z*yz
        sta WRMPYA
        lda matrix_yz
        sta WRMPYB
        nop
        lda a:cube_z+1,y
        ldx RDMPYL
        stx z:ZPAD+6
        sta WRMPYB
        nop
        lda matrix_yz+1
        ldx RDMPYL
        sta WRMPYA
        lda a:cube_z,y
        sta WRMPYB
        RW a16i16
        txa
        add z:ZPAD+6
        add RDMPYL
        sta matrix_z_yz
        
        RW a8i16
        lda z:ZPAD ;(yx + y)(yy + x)
        sta WRMPYA
        lda z:ZPAD+2
        sta WRMPYB
        nop
        lda z:ZPAD+1
        ldx RDMPYL
        stx z:ZPAD+6
        sta WRMPYB
        nop
        lda z:ZPAD+3
        ldx RDMPYL
        sta WRMPYA
        lda z:ZPAD
        sta WRMPYB
        RW a16i16
        txa
        add z:ZPAD+6
        add RDMPYL
        sta z:ZPAD+8
        
        lda z:ZPAD+8 ;(yx + y)(yy + x) + z*yz - (yx_yy + x_y)
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
        
        RW a8i16
        lda a:cube_z,y ;z*zz
        sta WRMPYA
        lda matrix_zz
        sta WRMPYB
        nop
        lda a:cube_z+1,y
        ldx RDMPYL
        stx z:ZPAD+6
        sta WRMPYB
        nop
        lda matrix_zz+1
        ldx RDMPYL
        sta WRMPYA
        lda a:cube_z,y
        sta WRMPYB
        RW a16i16
        txa
        add z:ZPAD+6
        add RDMPYL
        sta matrix_z_zz
        
        RW a8i16
        lda z:ZPAD ;(zx + y)(zy + x)
        sta WRMPYA
        lda z:ZPAD+2
        sta WRMPYB
        nop
        lda z:ZPAD+1
        ldx RDMPYL
        stx z:ZPAD+6
        sta WRMPYB
        nop
        lda z:ZPAD+3
        ldx RDMPYL
        sta WRMPYA
        lda z:ZPAD
        sta WRMPYB
        RW a16i16
        txa
        add z:ZPAD+6
        add RDMPYL
        sta z:ZPAD+8
        
        lda z:ZPAD+8 ;(zx + y)(zy + x) + z*zz - (zx_zy + x_y)
        add matrix_z_zz
        sub z:ZPAD+4
        sta matrix_pointz,y
        
donepolyrotation:
        iny
        iny
        cpy #16
        beq polyprojection
        jmp polyrotationloop
        
polyprojection:
        RW a8i16
        ldy #0
projectionloop:
@xpointpro:
        RW a16i16
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
@donepointpro:
        stz z:invertpointx
        stz z:invertpointy
        
        lda a:oldpointyword,y
        xba
        lsr
        ora a:oldpointxword,y
        tax
        
        RW a8i16
        lda #$00
        sta f:pseudobitmap,x
        
        RW a16i16
        
        lda a:pointxword,y
        sta a:oldpointxword,y
        
        lda a:pointyword,y
        sta a:oldpointyword,y
        xba
        lsr
        ora a:pointxword,y
        tax
        
        RW a8i16
        lda #$f0
        sta f:pseudobitmap,x
@nextloop:      
        iny
        iny
        cpy #16
        beq threeddone
        jmp projectionloop
threeddone:
        lda #1
        sta z:threeddoneflag
        
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
        VRAM_memcpy VRAM_MODE7_LOC, pseudobitmap, 3584, 0, 0, $18       ;Transfer first third of map to even VRAM addresses
        lda z:vramsplit
        dec
        sta z:vramsplit
        bra donevblankinit
  lastvblankinit:
        VRAM_memcpy y, (pseudobitmap+3584), 3584, 0, 0, $18       ;Transfer last third of map to even VRAM addresses
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
        VRAM_memcpy y, (pseudobitmap), 3584, 0, 0, $18       ;Transfer middle third of map to even VRAM addresses
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

.segment "ROM1"
incbin m7testpbm, "data/chunktest.png.pbm"

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
matrix_sx: .res 1
matrix_sy: .res 1
matrix_sz: .res 1

.segment "LORAM"
pointxword: .res 16
pointyword: .res 16
oldpointxword: .res 16
oldpointyword: .res 16

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

matrix_pointx: .res 16
matrix_pointy: .res 16
matrix_pointz: .res 16