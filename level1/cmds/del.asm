********************************************************************
* Del - File deletion utility
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*   5    From Tandy OS-9 Level One VR 02.00.00
*   6    Now option can be anywhere on command line,    BGP 03/01/13
*        and all files will be deleted.  Made smaller

         nam   Del
         ttl   File deletion utility

* Disassembled 98/09/10 22:43:13 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         endc

tylg     set   Prgrm+Objct   
atrv     set   ReEnt+rev
rev      set   $01
edition  set   6

         mod   eom,name,tylg,atrv,start,size

amode    rmb   1
         rmb   250
stack    rmb   200
size     equ   .

name     fcs   /Del/
         fcb   edition

HelpMsg  fcb   C$LF
         fcc   "Use: Del [-x] <path> {<path>} [-x]"
         fcb   C$CR

start    lda   ,x		get first char on command line
         cmpa  #C$CR		carriage return?
         beq   ShowHelp		if so, no params, show help
         lda   #READ.
         sta   <amode
         pshs  x		save param pointer
         bsr   GetOpts		get opts
         puls  x		get param pointer
L0043    lda   <amode
         os9   I$DeletX 
         bcs   Exit
         lda   ,x
         cmpa  #C$CR
         bne   L0043
ExitOk   clrb  
Exit     os9   F$Exit   

GetOpts  ldd   ,x+
         cmpa  #C$SPAC
         beq   GetOpts
         cmpa  #C$COMA
         beq   GetOpts
         cmpa  #C$CR
         beq   Return
         cmpa  #'-
         bne   SkipName
         eorb  #'X
         andb  #$DF
         bne   ShowHelp
         lda   #EXEC.
         sta   <amode
         ldd   #$2020
         std   -1,x		write over option
SkipName lda   ,x+
         cmpa  #C$SPAC
         beq   GetOpts
         cmpa  #C$COMA
         beq   GetOpts
CheckCR  cmpa  #C$CR
         bne   SkipName
Return   rts   

ShowHelp leax  >HelpMsg,pcr
         ldy   #80
         lda   #2		stderr
         os9   I$WritLn 	write help
         bra   ExitOk

         emod
eom      equ   *
         end

