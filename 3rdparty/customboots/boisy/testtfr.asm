         ifp1
         use   os9defs
         endc

tylg     set   Prgrm+Objct   
atrv     set   ReEnt+rev
rev      set   $00
edition  set   1

         mod   eom,name,tylg,atrv,start,size

stack    rmb   200
size     equ   .

name     fcs   /testmul/
         fcb   edition

start
         orcc  #IntMasks

* set up appropriate registers for test

* measure mul multiplying 0
         lda   #0
         ldb   #0

* measure mul multiplying alternating bit patterns
*         lda   #%01010101
*         ldb   #%10101010

top
* 100 instructions in series
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         tfr   a,b
         lbra  top

         clrb
         os9   F$Exit

         emod
eom      equ   *
         end
