********************************************************************
* Load - Load a module
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*   4      ????/??/??
* From Tandy OS-9 Level One VR 02.00.00.

         nam   Load
         ttl   Load a module

         use   defsfile.d

rev      set   $00
edition  set   4

         section data
u0000    rmb   200
         endsect

*         psect load_a,Prgrm+Objct,ReEnt+rev,edition,200,start
         section code

__start  os9   F$Load   
         bcs   Exit
         lda   ,x
         cmpa  #C$CR
         bne   start
         clrb  
Exit     os9   F$Exit   

         endsect
