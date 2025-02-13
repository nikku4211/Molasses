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
        sta z:matrixsx
        lda #INIT_SY
        sta z:matrixsy
        lda #INIT_SZ
        sta z:matrixsz
        
polyrotation:
matrixtprep:
        RW a8i8
        
        ;t1
        lda z:matrixsy
        sub z:matrixsz
        sta matrixt
        
        ;t2
        lda z:matrixsy
        add z:matrixsz
        sta matrixt+1
        
        ;t3
        lda z:matrixsx
        add z:matrixsz
        sta matrixt+2
        
        ;t4
        lda z:matrixsx
        sub z:matrixsz
        sta matrixt+3
        
        ;t5
        lda z:matrixsx
        add matrixt+1
        sta matrixt+4
        
        ;t6
        lda z:matrixsx
        sub matrixt
        sta matrixt+5
        
        ;t7
        lda z:matrixsx
        add matrixt
        sta matrixt+6
        
        ;t8
        lda matrixt+1
        sub z:matrixsx
        sta matrixt+7
        
        ;t9
        lda z:matrixsy
        sub z:matrixsx
        sta matrixt+8
        
        ;t10
        lda z:matrixsy
        add z:matrixsx
        sta matrixt+9
        
matrixproductprep:
        RW a16i8
        
        ;mA
        lda matrixt+1
        asl
        sta z:ZPAD
        lda matrixt
        asl
        tax
        lda sinlut+64,x ;sinlut+64 = coslut
        ldx z:ZPAD
        add sinlut+64,x
        sta matrixproduct
        
        ;mB
        ; lda matrixt+1
        ; asl
        ; sta z:ZPAD
        lda matrixt
        asl
        tax
        lda sinlut,x
        ldx z:ZPAD
        sub sinlut,x
        sta matrixproduct+2
        
        ;mC
        lda z:matrixsy
        asl
        tax
        lda sinlut,x
        asl
        sta matrixproduct+4
        
        ;mD
        lda matrixt+3
        asl
        sta z:ZPAD
        lda matrixt+2
        asl
        tax
          ;(sin(t3)-sin(t4))/2
        lda sinlut,x
        ldx z:ZPAD
        sub sinlut,x
        sta matrixproduct+6
        
        lda matrixt+6
        asl
        sta z:ZPAD
        lda matrixt+7
        asl
        sta z:ZPAD+2
        lda matrixt+4
        asl
        sta z:ZPAD+4
        lda matrixt+5
        asl
        tax ;(cos(t6)-cos(t5)+cos(t8)-cos(t7))/4
        lda sinlut+64,x
        ldx z:ZPAD+4
        sub sinlut+64,x
        ldx z:ZPAD+2
        add sinlut+64,x
        ldx z:ZPAD
        sub sinlut+64,x
        bpl :+
        lsr
        ora #$8000
        bra :++
:
        lsr
:
        add matrixproduct+6
        sta matrixproduct+6
        
        ;mE
        lda matrixt+3
        asl
        sta z:ZPAD
        lda matrixt+2 ;(cos(t3)+cos(t4))/2
        asl
        tax
        lda sinlut+64,x
        ldx z:ZPAD
        add sinlut+64,x
        sta matrixproduct+8
        
        lda matrixt+7
        asl
        sta z:ZPAD+4
        lda matrixt+6
        asl
        sta z:ZPAD+2
        lda matrixt+5
        asl
        sta z:ZPAD
        lda matrixt+4 ;(sin(t5)-sin(t6)+sin(t7)-sin(t8))/4
        asl
        tax
        lda sinlut,x
        ldx z:ZPAD
        sub sinlut,x
        ldx z:ZPAD+2
        sub sinlut,x
        ldx z:ZPAD+4
        sub sinlut,x
        bpl :+
        lsr
        ora #$8000
        bra :++
:
        lsr
:
        add matrixproduct+8
        sta matrixproduct+8
        
        ;mF
        lda matrixt+9
        asl
        sta z:ZPAD
        lda matrixt+8
        asl
        tax
        lda sinlut,x
        ldx z:ZPAD
        sub sinlut,x
        sta matrixproduct+10
        
        ;mG
        lda matrixt+2
        asl
        sta z:ZPAD
        lda matrixt+3 ;(cos(t4)-cos(t3))/2
        asl
        tax
        lda sinlut+64,x
        ldx z:ZPAD
        add sinlut+64,x
        sta matrixproduct+12
        
        lda matrixt+6
        asl
        sta z:ZPAD+4
        lda matrixt+7
        asl
        sta z:ZPAD+2
        lda matrixt+4
        asl
        sta z:ZPAD
        lda matrixt+5
        asl
        tax
            ;(sin(t6)-sin(t5)-sin(t8)-sin(t7))/4
        lda sinlut,x
        ldx z:ZPAD
        sub sinlut,x
        ldx z:ZPAD+2
        sub sinlut,x
        ldx z:ZPAD+4
        sub sinlut,x
        bpl :+
        lsr
        ora #$8000
        bra :++
:
        lsr
:
        add matrixproduct+12
        sta matrixproduct+12
        
        ;mH
        lda matrixt+3
        asl
        sta z:ZPAD
        lda matrixt+2
        asl
        tax ;(sin(t3)+sin(t4))/2
        lda sinlut,x
        ldx z:ZPAD
        add sinlut,x
        sta matrixproduct+14
        
        lda matrixt+6
        asl
        sta z:ZPAD+4
        lda matrixt+7
        asl
        sta z:ZPAD+2
        lda matrixt+4
        asl
        sta z:ZPAD
        lda matrixt+5
        asl
        tax ;(cos(t6)-cos(t5)+cos(t7)-cos(t8))/4
        lda sinlut+64,x
        ldx z:ZPAD
        sub sinlut+64,x
        ldx z:ZPAD+2
        add sinlut+64,x
        ldx z:ZPAD+4
        sub sinlut+64,x
        bpl :+
        lsr
        ora #$8000
        bra :++
:
        lsr
:
        add matrixproduct+14
        sta matrixproduct+14
        
        ;mI
        lda matrixt+9
        asl
        sta z:ZPAD
        lda matrixt+8
        asl
        tax
        lda sinlut+64,x
        ldx z:ZPAD
        add sinlut+64,x
        sta matrixproduct+16

setuprotations:
        
        ;p1
        lda matrixproduct
        add matrixproduct+6
        add matrixproduct+12
        sta matrixpointx
        
        lda matrixproduct+2
        add matrixproduct+8
        add matrixproduct+14
        sta matrixpointy
        
        lda matrixproduct+4
        add matrixproduct+10
        add matrixproduct+16
        sta matrixpointz
        
        ;p2
        lda matrixproduct
        sub matrixproduct+6
        add matrixproduct+12
        sta matrixpointx+2
        
        lda matrixproduct+2
        sub matrixproduct+8
        add matrixproduct+14
        sta matrixpointy+2
        
        lda matrixproduct+4
        sub matrixproduct+10
        add matrixproduct+16
        sta matrixpointz+2
        
        ;p3
        lda matrixproduct+12
        sub matrixproduct
        sub matrixproduct+6
        sta matrixpointx+4
        
        lda matrixproduct+14
        sub matrixproduct+2
        sub matrixproduct+8
        sta matrixpointy+4
        
        lda matrixproduct+16
        sub matrixproduct+4
        sub matrixproduct+10
        sta matrixpointz+4
        
        ;p4
        lda matrixproduct+12
        add matrixproduct+6
        sub matrixproduct
        sta matrixpointx+6
        
        lda matrixproduct+14
        add matrixproduct+8
        sub matrixproduct+2
        sta matrixpointy+6
        
        lda matrixproduct+16
        add matrixproduct+10
        sub matrixproduct+4
        sta matrixpointz+6
        
        ;p5
        lda matrixproduct
        add matrixproduct+6
        sub matrixproduct+12
        sta matrixpointx+8
        
        lda matrixproduct+2
        add matrixproduct+8
        sub matrixproduct+14
        sta matrixpointy+8
        
        lda matrixproduct+4
        add matrixproduct+10
        sub matrixproduct+16
        sta matrixpointz+8
        
        ;p6
        lda matrixproduct
        sub matrixproduct+6
        sub matrixproduct+12
        sta matrixpointx+10
        
        lda matrixproduct+2
        sub matrixproduct+8
        sub matrixproduct+14
        sta matrixpointy+10
        
        lda matrixproduct+4
        sub matrixproduct+10
        sub matrixproduct+16
        sta matrixpointz+10
        
        ;p7
        lda #0
        sub matrixproduct
        sub matrixproduct+6
        sub matrixproduct+12
        sta matrixpointx+12
        
        lda #0
        sub matrixproduct+2
        sub matrixproduct+8
        sub matrixproduct+14
        sta matrixpointy+12
        
        lda #0
        sub matrixproduct+4
        sub matrixproduct+10
        sub matrixproduct+16
        sta matrixpointz+12
        
        ;p8
        lda matrixproduct+6
        sub matrixproduct
        sub matrixproduct+12
        sta matrixpointx+14
        
        lda matrixproduct+8
        sub matrixproduct+2
        sub matrixproduct+14
        sta matrixpointy+14
        
        lda matrixproduct+10
        sub matrixproduct+4
        sub matrixproduct+16
        sta matrixpointz+14
        
rotatepoints:
        RW a8i16
        ldy #0
pointrotationloop:
@xpointrot:
        RW_forced a8i16
        stz z:ZPAD
        lda a:cube_x+1,y ;8.8 fixed * int8
        bpl :+
        lda a:matrixpointx+1,y
        sta WRMPYA
        lda #$ff
        sta WRMPYB
        nop
        nop
        nop
        ldx RDMPYL
        stx z:ZPAD
:
        lda a:cube_x+1,y
        sta WRMPYA
        lda a:matrixpointx+1,y
        sta WRMPYB
        nop
        nop
        nop
        ldx RDMPYL
        ; stx z:ZPAD
        ; lda a:cube_x+1,y
        ; sta WRMPYA
        lda a:matrixpointx,y
        sta WRMPYB
        nop
        nop
        RW a16i16
        txa
        xba
        and #$ff00
        add RDMPYL
        add z:ZPAD
        sta a:matrixpointx,y
@ypointrot:       
        RW a8i16
        stz z:invertpointy
        lda a:cube_y+1,y ;8.8 fixed * int8
        sta WRMPYA
        lda a:matrixpointy+1,y
        sta WRMPYB
        nop
        nop
        nop
        ldx RDMPYL
        ; stx z:ZPAD
        ; lda a:cube_y+1,y
        ; sta WRMPYA
        lda a:matrixpointy,y
        sta WRMPYB
        nop
        nop
        RW a16i16
        ;lda z:ZPAD
        txa
        xba
        and #$ff00
        add RDMPYL
        sta a:matrixpointy,y
@zpointrot:
        RW a8i16
        stz z:invertpointz
        lda a:cube_z+1,y ;8.8 fixed * int8
        sta WRMPYA
        lda a:matrixpointz+1,y
        sta WRMPYB
        nop
        nop
        nop
        ldx RDMPYL
        ; stx z:ZPAD
        ; lda a:cube_z+1,y
        ; sta WRMPYA
        lda a:matrixpointz,y
        sta WRMPYB
        nop
        nop
        RW a16i16
        ;lda z:ZPAD
        txa
        xba
        and #$ff00
        add RDMPYL
        sta a:matrixpointz,y
@donepointrot:
        iny
        iny
        cpy #16
        beq polyprojection
        jmp pointrotationloop
        
polyprojection:
        RW a8i16
        ldy #0
projectionloop:
@xpointpro:
        RW a16i16
        stz z:invertpointx
        ; get cube x points and divide by z
        lda a:matrixpointx,y
        sub z:camx
        cmp #$8000
        bcc @notnegativex
        sta z:invertpointx
        neg
@notnegativex:
        sta WRDIVL
        lda a:matrixpointz,y
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
        lda a:matrixpointy,y
        sub z:camy
        cmp #$8000
        bcc @notnegativey
        sta z:invertpointy
        neg
@notnegativey:
        sta WRDIVL
        lda a:matrixpointz,y
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
        ;inc z:matrixsx
        inc z:matrixsy
        ;inc z:matrixsz
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
matrixsx: .res 1
matrixsy: .res 1
matrixsz: .res 1

.segment "LORAM"
pointxword: .res 16
pointyword: .res 16
oldpointxword: .res 16
oldpointyword: .res 16

matrixt: .res 10

matrixproduct: .res 18

matrixpointx: .res 16
matrixpointy: .res 16
matrixpointz: .res 16