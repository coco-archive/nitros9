********************************************************************
* CO80 - WordPak 80-RS co-driver for CCIO
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*   2      ????/??/??
* From Tandy OS-9 Level One VR 02.00.00
*
*          2003/09/22  Rodney Hamilton
* recoded dispatch table fcbs

         nam   CO80
         ttl   WordPak 80-RS co-driver for CCIO

* Disassembled 98/08/23 17:58:20 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         use   cciodefs
         endc

tylg     set   Systm+Objct   
atrv     set   ReEnt+rev
rev      set   $00
edition  set   2

         mod   eom,name,tylg,atrv,start,size

u0000    rmb   0
size     equ   .
         fcb   $06 

name     fcs   /CO80/
         fcb   edition

start    equ   *
         lbra  Init
         lbra  Write
         lbra  GetStat
         lbra  SetStat
         lbra  Term

* Init
Init     ldx   #$FF78
         lda   #$06
         sta   $01,x
         sta   ,x
         lda   #$08
         sta   $01,x
         clr   ,x
         lda   #$0E
         sta   $01,x
         clr   ,x
         lbsr  L0152
         lbsr  L0229
         ldd   #$07D0
         lbsr  L0189
         ldb   <V.COLoad,u
         orb   #$04
         bra   L004F
* Term
Term     ldb   <V.COLoad,u
         andb  #$FB
L004F    stb   <V.COLoad,u
         clrb  
         rts   
* GetStat
GetStat  cmpa  #SS.Cursr
         bne   SetStat
         ldy   R$Y,y
         clra  
         ldb   <V.C80X,u
         addb  #$20
         std   $06,y
         ldb   <V.C80Y,u
         addb  #$20
         std   R$X,y
         ldx   #$FF78
         lda   #$0D
         sta   $01,x
         lbsr  L0174
         lda   ,x
         lbsr  L0174
         lda   ,x
         sta   $01,y
* no operation entry point
L007D    clrb  
         rts   
* SetStat
SetStat  ldb   #E$UnkSvc
         coma  
         rts   
* Write
Write    ldx   #$FF78
         cmpa  #$0E
         bcs   L00B6
         cmpa  #$1E
         bcs   L007D
         cmpa  #$20
         lbcs  L01F2
         cmpa  #$7F
         bcs   L0106
         cmpa  #$C0
         bls   L00A6
         anda  #$1F
         suba  #$01
         cmpa  #$19
         bhi   L00B2
         bra   L0106
L00A6    cmpa  #$AA
         bcs   L00B2
         ora   #$10
         anda  #$1F
         cmpa  #$1A
         bcc   L0106
L00B2    lda   #$7F
         bra   L0106
L00B6    leax  >L00C5,pcr
         lsla  
         ldd   a,x
         leax  d,x
         pshs  x
         ldx   #$FF78
         rts   

* display functions dispatch table
L00C5    fdb   L007D-L00C5  $ffb8  $00:no-op (null)
         fdb   L0152-L00C5  $008d  $01:HOME cursor
         fdb   L01A2-L00C5  $00dd  $02:CURSOR XY
         fdb   L0179-L00C5  $00b4  $03:ERASE LINE
         fdb   L017B-L00C5  $00b6  $04:ERASE TO EOL
         fdb   L0211-L00C5  $014c  $05:CURSOR ON/OFF
         fdb   L0115-L00C5  $0050  $06:CURSOR RIGHT
         fdb   L007D-L00C5  $ffb8  $07:no-op (bel:handled in CCIO)
         fdb   L00E1-L00C5  $001c  $08:CURSOR LEFT
         fdb   L00F3-L00C5  $002e  $09:CURSOR UP
         fdb   L0121-L00C5  $005c  $0A:CURSOR DOWN
         fdb   L0186-L00C5  $00c1  $0B:ERASE TO EOS
         fdb   L0184-L00C5  $00bf  $0C:CLEAR SCREEN
         fdb   Do0D-L00C5  $003c  $0D:RETURN

* $08 - cursor left
L00E1    ldd   <V.C80X,u	get CO80 X/Y
         bne   L00E8		branch if not at start
         clrb  	
         rts   	
L00E8    decb  
         bge   L00EE
         ldb   #$4F
         deca  
L00EE    std   <V.C80X,u
         bra   L014F

* $09 - cursor up
L00F3    lda   <V.C80X,u
         beq   L00FF
         deca  
         sta   <V.C80X,u
         lbra  L01CC
L00FF    clrb  
         rts   

* $0D - move cursor to start of line (carriage return)
Do0D     clr   <V.C80Y,u
         bra   L014C

L0106    ora   <V.5A,u
         pshs  a
         bsr   L0174
         puls  a
         ldb   #$0D
         stb   $01,x
         sta   ,x

* $06 - cursor right
L0115    inc   <V.C80Y,u
         lda   <V.C80Y,u
         cmpa  #$4F
         ble   L014C
         bsr   Do0D

* $0A - cursor down (line feed)
L0121    lda   <V.C80X,u
         cmpa  #$17
         bge   L012E
         inca  
         sta   <V.C80X,u
         bra   L014F
L012E    ldd   <V.54,u
         lbsr  L01DC
         ldd   <V.54,u
         addd  #80
         bsr   L0161
         std   <V.54,u
         bsr   L018E
         ldd   <V.54,u
         bsr   L016B
         lda   #$08
         sta   $01,x
         stb   ,x
L014C    lda   <V.C80X,u
L014F    lbra  L01CC

* $01 - home cursor
L0152    clr   <V.C80X,u
         clr   <V.C80Y,u
         ldd   <V.54,u
         std   <V.56,u
         lbra  L01DC
L0161    cmpd  #$07D0
         blt   L016A
         subd  #$07D0
L016A    rts   
L016B    lsra  
         rorb  
         lsra  
         rorb  
         lsra  
         rorb  
         lsra  
         rorb  
         rts   
L0174    lda   $01,x
         bpl   L0174
         rts   

* $03 - erase line
L0179    bsr   Do0D		do a CR
L017B    lda   <V.C80X,u
         inca  
         ldb   #80		line length
         mul   
         bra   L0189

* $0C - clear screen
L0184    bsr   L0152		do home cursor, then erase to EOS

* $0B - erase to end of screen
L0186    ldd   #80*24
L0189    addd  <V.54,u
         bsr   L0161
L018E    bsr   L016B
         bsr   L0174
         lda   #$0B
         sta   $01,x
         stb   ,x
         lda   #$0D
         sta   $01,x
         lda   #$20
         sta   ,x
L01A0    clrb  
         rts   

* $02 XX YY - move cursor to col XX-32, row YY-32
L01A2    leax  >L01B0,pcr
         ldb   #$02
L01A8    stx   <V.RTAdd,u
         stb   <V.NGChr,u
         clrb  
         rts   
L01B0    ldx   #$FF78
         lda   <V.NChr2,u
         ldb   <V.NChar,u
         subb  #$20
         blt   L01A0
         cmpb  #$4F
         bgt   L01A0
         suba  #$20
         blt   L01A0
         cmpa  #$17
         bgt   L01A0
         std   <V.C80X,u
L01CC    ldb   #$50
         mul   
         addb  <V.C80Y,u
         adca  #$00
         addd  <V.54,u
         bsr   L0161
         std   <V.56,u
L01DC    pshs  b,a
         bsr   L0174
         lda   #$0A
         sta   $01,x
         lda   ,s+
         sta   ,x
         lda   #$09
         sta   $01,x
         lda   ,s+
         sta   ,x
         clrb  
         rts   
L01F2    cmpa  #$1F
         bne   L0201
         lda   <V.NChr2,u
         cmpa  #$21
         beq   L0205
         cmpa  #$20
         beq   L020C
L0201    comb  
         ldb   #E$Write
         rts   
L0205    lda   #$80
         sta   <V.5A,u
         clrb  
         rts   
L020C    clr   <V.5A,u
L020F    clrb  
         rts   

* $05 XX - set cursor off/on/color per XX-32
L0211    leax  >L0219,pcr
         ldb   #$01
         bra   L01A8
L0219    ldx   #$FF78
         lda   <V.NChr2,u	get next character
         cmpa  #$20		cursor code valid?
         blt   L0201		 no, error
         beq   L022D
         cmpa  #$2A		color code in range?
         bgt   L020F		 no, ignore
L0229    lda   #$05		cursor on (all colors=on)
         bra   L022F
L022D    lda   #$45		cursor off
L022F    ldb   #$0C
         stb   $01,x
         sta   ,x
         clrb  
         rts   

         emod
eom      equ   *
         end

