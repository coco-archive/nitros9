********************************************************************
* DDisk - Dragon Floppy driver
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*   -      ????/??/??
* Original Dragon Data distribution version
*
* Added Defines for IO ports.
*		   2004/11/09, P.Harvey-Smith
*	
* Dragon Alpha code, 2004-11-09, P.Harvey-Smith.
*	I am not sure of how to disable NMI on the Alpha, it is
*	simulated in software using the NMIFlag.
*
*   	The Dragon Alpha/Professional uses the same FDC chip as 
*	DragonDos, however it is mapped between FF2C and FF2F,
*	also the register order is REVERSED, so command/status is at
* 	FF2F.
*
* 	Drive Selects, motor and write precompensation is controled
*	through the IO port of an AY-8912, which itself is connected
*	to a 3rd PIA mapped at FF24 to FF27, this PIA also has it's
*	inturrupt lines connected to the CPU's FIRQ.
*
* 2004-11-15, P.Harvey-Smith.
*	Fixed bug in inturrupt handling code that was making the 
*	Dragon Alpha crash if a disk was accessed with no disk 
*	in the drive. As the Alpha is using a simulated NMI disable
* 	we have to ensure that the NMI enabling routine has completed
*	BEFORE isuing a command to the disk controler, or if the 
* 	inturrupt happens in the middle of the enable routine it 
*	causes the machine to crash !
*
* 2004-11-24, P.Harvey-Smith.
*	Fixed up so that double sided disks now work, origional 
* 	double sided code taken from Jon Bird's pages at :
*	http://www.onastick.clara.net/dragon.html and modified 
* 	for NitrOS9.
* 
* 2004-11-27, P.Harvey-Smith.
* 	Reformatted with tab=8.
*
* 2005-04-22, P.Harvey-Smith.
*	Hopefully fixed a bug that was causing the Dragon 64 target to
*	crash and burn when reading disks, this made a successfull boot 
*	almost imposible ! Fixed by writing disk command before writing
*	disc control register, the Alpha target needs them the other way 
*	around. Still has a problem doing lots of retries.
*
* 2005-04-24, P.Harvey-Smith.
*	Fixed constant lost data errors reading disks, again by slightly 
*	re-ordering the instructions in the read data loop.
*	
* 2005-04-24, P.Harvey-Smith.
*	Removed debugging code/messages.

         nam   DDisk
         ttl   Dragon Floppy driver

* Disassembled 02/04/21 22:37:46 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile.dragon
         endc

		IFNE	DragonAlpha

* Dragon Alpha has a third PIA at FF24, this is used for
* Drive select / motor control, and provides FIRQ from the
* disk controler.

DPPIADA		EQU	DPPIA2DA
DPPIACRA	EQU	DPPIA2CRA		
DPPIADB		EQU	DPPIA2DB		
DPPIACRB	EQU	DPPIA2CRB

PIADA		EQU	DPPIADA+IO	; Side A Data/DDR
PIACRA		EQU	DPPIACRA+IO	; Side A Control.
PIADB		EQU	DPPIADB+IO	; Side A Data/DDR
PIACRB		EQU	DPPIACRB+IO	; Side A Control.

;WD2797 Floppy disk controler, used in Alpha Note registers in reverse order !
DPCMDREG	EQU	DPCmdRegA	; command/status			
DPTRKREG	EQU	DPTrkRegA	; Track register
DPSECREG	EQU	DPSecRegA	; Sector register
DPDATAREG	EQU	DPDataRegA	; Data register

CMDREG		EQU	DPCMDREG+IO	; command/status			
TRKREG		EQU	DPTRKREG+IO	; Track register
SECREG		EQU	DPSECREG+IO	; Sector register
DATAREG		EQU	DPDATAREG+IO	; Data register

; Disk IO bitmasks

NMIEn    	EQU	NMIEnA
WPCEn    	EQU   	WPCEnA
SDensEn  	EQU   	SDensEnA
MotorOn  	EQU   	MotorOnA 

; These are the bits that we know the function of on the Alpha interface
KnownBits	EQU	Drive0A+Drive1A+Drive2A+Drive3A+MotorOnA+SDensEnA+WPCEnA

		ELSE
		
DPPIADA		EQU	DPPIA1DA
DPPIACRA	EQU	DPPIA1CRA		
DPPIADB		EQU	DPPIA1DB		
DPPIACRB	EQU	DPPIA1CRB

PIADA		EQU	DPPIADA+IO	; Side A Data/DDR
PIACRA		EQU	DPPIACRA+IO	; Side A Control.
PIADB		EQU	DPPIADB+IO	; Side A Data/DDR
PIACRB		EQU	DPPIACRB+IO	; Side A Control.

;WD2797 Floppy disk controler, used in DragonDos.
DPCMDREG	EQU	DPCmdRegD	; command/status			
DPTRKREG	EQU	DPTrkRegD	; Track register
DPSECREG	EQU	DPSecRegD	; Sector register
DPDATAREG	EQU	DPDataRegD	; Data register

CMDREG		EQU	DPCMDREG+IO	; command/status			
TRKREG		EQU	DPTRKREG+IO	; Track register
SECREG		EQU	DPSECREG+IO	; Sector register
DATAREG		EQU	DPDATAREG+IO	; Data register

; Disk IO bitmasks

NMIEn    	EQU	NMIEnD
WPCEn    	EQU   	WPCEnD
SDensEn  	EQU   	SDensEnD
MotorOn  	EQU   	MotorOnD

		ENDC

tylg	set   	Drivr+Objct   
atrv    set   	ReEnt+rev
rev     set  	$00
edition set   	3

MaxDrv   set   4

         mod   eom,name,tylg,atrv,start,size
		
		org	DrvBeg
		RMB   	MaxDrv*DrvMem
CDrvTab	  	rmb   	2
DrivSel   	rmb   	1	; Saved drive mask
Settle	 	rmb	1	; Head settle time
SavePIA0CRB	rmb 	1	; Saved copy of PIA0 control reg b
SaveACIACmd	rmb	1	; Saved copy of ACIA command reg
BuffPtr	 	rmb	2	; Buffer pointer
SideSel	 	rmb	1	; Side select.
NMIFlag	 	rmb	1	; Flag for Alpha, should this NMI do an RTI ?

DskError	rmb	1	; hardware disk error	

VIRQPak  	rmb   	2	; Vi.Cnt word for VIRQ
u00B3    	rmb   	2	; Vi.Rst word for VIRQ
u00B5    	rmb   	1	; Vi.Stat byte for VIRQ (drive motor timeout)

VIRQInstalled	rmb	1	; Is VIRQ Installed yet ?
size     	equ  	.

	fcb   	$FF 
name    equ   	*
        fcs   	/DDisk/
        fcb   	edition

VIRQCnt fdb   	TkPerSec*4     Initial count for VIRQ (4 seconds)

start   lbra  	Init		; Initialise Driver
        lbra  	Read		; Read sector
        lbra  	Write		; Write sector
        lbra 	GetStat		; Get status
        lbra  	SetStat		; Set status
        lbra  	Term		; Terminate device

IRQPkt   fcb   	$00 		; Normal bits (flip byte)
         fcb   	$01		; Bit 1 is interrupt request flag (Mask byte)
         fcb   	10		; Priority byte


* Init
*
* Entry:
*    Y  = address of device descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
DragonDebug	EQU	0
Init    
	IFNE	DragonDebug
	pshs	x		; This is here so I can find disk driver in mess
	ldx	#$AA55		; by setting register breakpoint to X=$AA55 !
	puls	x
	ENDC

	clra
	sta	>D.DskTmr	; Zero motor timer
	
	IFNE	DragonAlpha	; Turn off all drives
	lbsr	AlphaDskCtl
	ELSE
        sta   	>DskCtl
	ENDC
		 
        ldx   	#CmdReg		; Reset controler
        lda  	#FrcInt
        sta   	,x
        lbsr  	Delay
        lda   	,x
        lda   	#$FF
        ldb   	#MaxDrv
        leax  	DrvBeg,u
		 
InitDriveData    
	sta   	DD.Tot,x	; Set total sectors = $FF
        sta   	<V.Trak,x	; Set current track = 0
        leax  	<DrvMem,x	; Skip to next drive
        decb  
        bne   	InitDriveData
         
	leax  	>NMIService,pcr	; Setup NMI handler
        stx   	>D.XNMI+1
        lda   	#$7E		; $7E = JMP
        sta   	>D.XNMI
		 
	clr	VIRQInstalled,u	;flag not installed yet

	pshs  	y              	; save device dsc. ptr
	leay  	>u00B5,u       	; point to Vi.Stat in VIRQ packet
        tfr   	y,d            	; make it the status register ptr for IRQ
        leay  	>IRQSvc,pc     	; point to IRQ service routine
        leax  	>IRQPkt,pc     	; point to IRQ packet
        os9   	F$IRQ          	; install IRQ
        puls  	y              	; Get back device dsc. ptr
		 
        ldd   	#$0100		; Request a page of system ram
        pshs  	u		; used to verify writes
        os9   	F$SRqMem 
        tfr   	u,x
        puls  	u
        bcs   	Return
        stx   	>BuffPtr,u	; Save verify page pointer
        clrb  
Return  rts   


* GetStat
*
* Entry:
*    A  = function code
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
GetStat

* Term
*
* Entry:
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Term    clrb  
        rts   

* Read
*
* Entry:
*    B  = MSB of the disk's LSN
*    X  = LSB of the disk's LSN
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Read     	
	lda   	#$91		; Retry count
        cmpx  	#$0000		; LSN ?
        bne   	ReadDataWithRetry	; No : Just do read,
        bsr   	ReadDataWithRetry	; Yes : do read and copy disk params
        bcs   	ReadDataExit
        ldx   	PD.Buf,y
        pshs  	y,x
        ldy   	>CDrvTab,u
        ldb   	#DD.Siz-1 
L0082   lda   	b,x
        sta   	b,y
        decb  
        bpl   	L0082
        clrb  
        puls  	pc,y,x
ReadDataExit    
	rts   

; Read Retry

ReadDataRetry    
	bcc   	ReadDataWithRetry	; Retry entry point
        pshs  	x,b,a
        lbsr  	ResetTrack0	; Reset track 0
        puls  	x,b,a

ReadDataWithRetry    
	pshs  	x,b,a		; Normal entry point
        bsr   	DoReadData
        puls  	x,b,a
        bcc  	ReadDataExit
        lsra  			; Check for retry
        bne   	ReadDataRetry

DoReadData    
	lbsr  	SeekTrack
        bcs   	ReadDataExit
        ldx   	PD.Buf,y	; Target address for data
        pshs  	y,dp,cc
        ldb   	#ReadCmnd	; Read command
        bsr   	PrepDiskRW	; Prepare disk 

DoReadDataLoop    
	lda   	<DPPIACRB	; Is data ready ?
        bmi   	ReadDataReady	; Yes : read it
        leay  	-1,y			
        bne   	DoReadDataLoop
        bsr   	RestoreSavedIO
        puls  	y,dp,cc			
        lbra  	RetReadError	; Return read error to caller

ReadDataWait 
	sync			; Sync to inturrupts, wait for data
	
ReadDataReady
	lda   	<DPDataReg	; Read data from FDC
        ldb   	<DPPIADB	; Clear PIA inturrupt status
        sta   	,x+		; save data in memory
        bra   	ReadDataWait	; do next
	 
PrepDiskRW    

	clr	DskError,u
	
	lda   	#$FF		; Make DP=$FF, to make io easier
        tfr   	a,dp
        lda   	<DPAciaCmd 	; Save ACIA Command reg	
        sta   	>SaveACIACmd,u
        anda  	#$FE		; Disable ACIA inturrupt
        sta   	<DPAciaCmd 	
        bita  	#$40		; Is Tx inturrupt enabled ?
        beq   	L00DE
L00D8   lda   	<DPAciaStat	; Yes, wait for Tx to complete
        bita  	#$10
        beq   	L00D8
		 
L00DE   orcc  	#$50		; Mask inturrupts
        lda   	<DPPia0CRB	; Save PIA0 IRQ Status
        sta   	>SavePIA0CRB,u	
        lda   	#$34		; Disable it.
        sta   	<DPPia0CRB	
	lda   	<DPACIACmd	; Disable ACIA Inturrupt
        anda  	#$FE
        sta   	<DPACIACmd	
        lda   	<DPPIACRB	; Set PIA to generate FIRQ on FDC DRQ
        ora   	#$03
        sta   	<DPPIACRB	
        lda   	<DPPIADB	; Clear any outstanding inturrupt	
        ldy   	#$FFFF
        lda   	#NMIEn+MotorOn	; Enable NMI, and turn motor on
        ora   	>DrivSel,u	; mask in drives
        ORB   	>SideSel,U 	; Set up Side		 
         
	IFNE	DragonAlpha	; Turn on drives & NMI
	lbsr	AlphaDskCtl
        stb   	<DPCmdReg	; issue command to controler 
	ELSE
        stb   	<DPCmdReg	; issue command to controler 
        sta   	<DPDskCtl
	ENDC
		 		 
		 
	rts  
		 
;
; Restore saved iO states of peripherals.
;

RestoreSavedIO
	lda   	>DrivSel,u	; Deselect drives, but leave motor on
        ora   	#MotorOn
	IFNE	DragonAlpha	; Turn off drives & NMI
	lbsr	AlphaDskCtl
	ELSE
        sta   	<DPDskCtl
	ENDC
         
	lda   	>SavePIA0CRB,u	; Recover PIA0 state	
        sta   	<DPPia0CRB	
        lda   	<DPPIACRB	; Recover ACIA state
        anda  	#$FC
        sta   	<DPPIACRB	; Disable Drive FIRQ source.
        lda   	>SaveACIACmd,u
        sta   	<DPAciaCmd	
        rts   

* Write
*
* Entry:
*    B  = MSB of the disk's LSN
*    X  = LSB of the disk's LSN
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Write   lda   	#$91		; Retry byte
L0124   pshs  	x,b,a
        bsr   	DoWrite		; Attempt to do write
        puls  	x,b,a
        bcs   	WriteDataRetry	; On error, retry
        tst   	<PD.Vfy,y	; Written, should we verify ?
        bne   	WriteDone	; no : return
        lbsr  	WriteVerify	; yes : verify write
        bcs   	WriteDataRetry	; verify error, retry write
WriteDone    
	clrb  			; Return status ok
        rts   
		 
WriteDataRetry    
	lsra  			; Retry data write
        lbeq  	RetWriteError	; All retries exhausted ?, return error
        bcc   	L0124
        pshs  	x,b,a		; Reset to track 0
        lbsr  	ResetTrack0
        puls  	x,b,a
        bra   	L0124
		 
DoWrite lbsr  	SeekTrack	; Seek to correct track & sector
        lbcs  	ReadDataExit
        ldx   	PD.Buf,y	; Get data buffer in X
        pshs  	y,dp,cc
        ldb   	#WritCmnd	; Write command
		 
WriteTrackCmd    
	lbsr  	PrepDiskRW	; Prepare for disk r/w
        lda   	,x+		; get byte to write
L015A   ldb   	<DPPIACRB	; Ready to write ?
        bmi   	WriteDataReady	; Yes, do it.
        leay  	-1,y
        bne   	L015A
        bsr   	RestoreSavedIO	; Restore saved peripheral states
        puls  	y,dp,cc
        lbra  	RetWriteError	; Return write error

WriteDataWait    
	lda   	,x+		; Get next byte to write
        sync  			; Wait for drive
WriteDataReady    
	sta   	<DPDataReg	; Write data to FDC
        ldb   	<DPPIADB	; Clear pending FDC inturrupt
        bra   	WriteDataWait
	

; The following block of code is needed for the Dragon Alpha, because
; we currently do not know how to disable it's NMI in hardware,
; So we check a flag here, and if set we simply return from inturrupt
; as if nothing happened !

NMIService
	IFNE	DragonAlpha		
	pshs	cc		; Save flags
	tst	>NMIFlag,u	; Check NMI enable flag 
	bne	DoNMI		; if enabled, continue with handler
	puls	cc		; else restore flags and return
	RTI
		
DoNMI	puls	cc		; restore flags
	ENDC
	
RealNMI    
	leas  	R$Size,s	; Drop regs from stack
        bsr   	RestoreSavedIO	; Restore saved IO states
        puls  	y,dp,cc
        ldb   	>CmdReg

	stb	DskError,u

	bitb  	#LostMask	; check for lost record
        lbne  	RetReadError	; yes : return read error
        lbra  	TestForError	; esle test for other errors
	 
; Verify a written sector.
WriteVerify    
	pshs  	x,b,a				
        ldx   	PD.Buf,y	; Swap buffer pointers
        pshs  	x
        ldx   	>BuffPtr,u	
        stx   	PD.Buf,y
        ldx   	4,s
        lbsr  	DoReadData	; Read data back in
        puls  	x
        stx   	PD.Buf,y	; Swab buffer pointers back
        bcs   	VerifyEnd
        lda   	#$20
        pshs  	u,y,a
        ldy   	>BuffPtr,u
        tfr   	x,u
VerifyLoop    
	ldx   	,u		; Compare every 4th word
        cmpx  	,y
        bne   	VerifyErrorEnd
        leau  	8,u
        leay  	8,y		; Increment pointers
        dec   	,s
        bne   	VerifyLoop
        bra   	VerifyEndOk	; Verify succeeded.
VerifyErrorEnd    
	orcc  	#Carry		; Flag error
VerifyEndOk    
	puls  	u,y,a
VerifyEnd    
	puls  	pc,x,b,a
;
; Seek to a track
;
SeekTrack
	CLR   	>Settle,U 	; default no settle
        LBSR  	SelectDrive	; select and start correct d
        TSTB
        BNE   	E.Sect 

	TFR   	X,D 
        LDX   	>CDrvTab,U 
        CMPD  	#0		; Skip calculation of track 0
        BEQ   	SeekT1 
        CMPD  	DD.TOT+1,X      ; Has an illegal LSN been
        BLO   	SeekT2 
E.Sect  COMB
        LDB   	#E$Sect 
        RTS
		 
SeekT2  CLR   	,-S            	; Calculate track number 
        SUBD  	PD.T0S,Y 	; subtract no. of sectors in track 0
        BHS   	SeekT4 
        ADDD  	PD.T0S,Y 	; if -ve we are on track 0, so add back on again
	BRA   	SeekT3 
SeekT4  INC   	,S 
        SUBD  	DD.Spt,X 	; sectors per track for rest of disk
        BHS   	SeekT4 		; repeat, until -ve, incrementing track count
        ADDD  	DD.Spt,X 	; re add sectors/track to get sector number on track

; At this point the byte on the top of the stack contains the track
; number, and B contains the sector number on that track.

SeekT3  PULS  	A 		; retrieve track count
        LBSR  	SetWPC         	; set write precompensation
        PSHS  	B 
        LDB   	DD.Fmt,X     	; Is the media double sided ?
        LSRB
        BCC   	SingleSidedDisk	; skip if not
        LDB   	PD.Sid,Y     	; Is the drive double sided ?
        DECB
        BNE   	SetupSideMask 	; yes : deal with it.
        PULS  	B               ; No then its an error
        COMB
        LDB   	#E$BTyp 
        RTS
		 
SetupSideMask	
	BSR   	SetSide		; Media & drive are double sided
	BRA   	SeekT9 

SingleSidedDisk
	clr   	>SideSel,U	; Single sided, make sure sidesel set correctly
	BRA   	SeekT9
		 
SeekT1  clr   	>SideSel,U	; make sure sidesel is always 0 if lsn0
	PSHS  	B 
SeekT9  LDB   	PD.Typ,Y  	; Dragon and Coco disks
        BITB  	#TYP.SBO       	; count sectors from 1 no
        BNE   	SeekT8 
        PULS  	B 
        INCB			; so increment sector number
        BRA   	SeekT11 
SeekT8  PULS  	B		; Count from 0 for other types

SeekT11 STB   	>SecReg 	; Write sector number to controler
        LBSR  	Delay 
        CMPB  	>SecReg 
        BNE   	SeekT11  			

SeekTS  LDB   	<V.Trak,X	; Entry point for SS.WTrk command
        STB   	>TrkReg 
        TST   	>Settle,U	; If settle has been flagged then wait for settle
        BNE   	SeekT5 	 
        CMPA  	<V.Trak,X	; otherwise check if this is  
        BEQ   	SeekT6   	; track number to the last
		 
SeekT5  STA   	<V.Trak,X	; Do the seek
        STA   	>DataReg 	; Write track no to controler
        LDB   	#SeekCmnd 
        ORB   	PD.Stp,Y	; Set Step Rate according to Parameter block
        LBSR  	FDCCommand 
        PSHS  	X 
        LDX   	#$222E		; Wait for head to settle
SeekT7  LEAX  	-1,X 
        BNE   	SeekT7 
        PULS  	X 

SeekT6  CLRB			; return no error to caller
        RTS

; Set Side2 Mask
; A contains the track number on entry
SetSide LSRA			; Get bit 0 into carry & devide track no by 2
	PSHS  	A  
	BCC   	Side0          	; Side 0 if even track no.
        LDA    	#Sid2Sel	; Odd track no. so side 2
	BRA	Side
Side0   CLRA
Side    STA   	>SideSel,U 
        PULS  	A,PC 

;
; Select drive and start drive motors.
; On entry A=drive number.
;

SelectDrive    
	lbsr  	StartMotor	; Start motor
        lda   	<PD.Drv,y	; Check it's a valid drive
        cmpa  	#MaxDrv
        bcs   	SelectDriveValid	; yes : continue
		 
RetErrorBadUnit
        comb  			; Return bad unit error
        ldb   	#E$Unit
        rts   

SelectDriveValid    
	pshs  	x,b,a		; Unit valid so slect it
        sta   	>DrivSel,u	; Get DD table address
        leax  	DrvBeg,u	; Calculate offset into table
        ldb   	#DrvMem
        mul   
        leax  	d,x
        cmpx  	>CDrvTab,u
        beq   	SelectDriveEnd
        stx   	>CDrvTab,u	; Force seek if different drive
        com   	>Settle,u
SelectDriveEnd    
	puls  	pc,x,b,a

;
; Analise device status return.
;

TestForError    
	bitb  	#ErrMask
        beq   	TestErrorEnd
        bitb  	#NotRMask	; not ready
        bne   	RetErrorNotReady
        bitb  	#WPMask		; Write protect
        bne   	RetErrorWP
        bitb  	#RTypMask	; Wrong type ?
        bne   	RetWriteError
        bitb  	#RNFMask	; Record Not found
        bne   	RetErrorSeek
        bitb  	#CRCMask
        bne   	RetErrorCRC
TestErrorEnd   
	clrb  
        rts   
;		 
; Return error code
;

RetErrorNotReady    
	comb  
        ldb   	#E$NotRdy
        rts   
RetErrorWP    
	comb  
        ldb   	#E$WP
        rts   
RetWriteError    	
	comb  
        ldb   	#E$Write
        rts   
RetErrorSeek    
	comb  
        ldb   	#E$Seek
        rts   
RetErrorCRC    
	comb  
        ldb   	#E$CRC
         rts   
RetReadError
	comb  
        ldb   	#E$Read
        rts   
;		 
; Issue a command to FDC and wait till it's ready
;

FDCCommand    
	bsr   	FDCCmd
FDCCmdWait    
	ldb   	>CmdReg		; Poll until not busy
        bitb  	#$01
        beq   	Delay3
	bra	FDCCmdWait

FDCCmdMotorOn    
 	lda   	#MotorOn	; Turn on motor
        ora   	>DrivSel,u

	IFNE	DragonAlpha
	lbsr	AlphaDskCtl
	ELSE
        sta   	>DskCtl
	ENDC

	bsr	SetupVIRQ
		
        stb   	>CmdReg		; Send Command to FDC
        rts   

SetupVIRQ
	pshs	D
        ldd   	>VIRQCnt,pc    	; Get VIRQ initial count value
        std   	>VIRQPak,u      ; Save it
	lda	VIRQInstalled,u	; Installed yet ?
	beq   	DoInsVIRQ       ; Not installed yet, try installing it
SetupVIRQExit
	PULS	D
	rts
	
DoInsVIRQ
	bsr	InsVIRQ
	bra	SetupVIRQExit
		
InsVIRQ pshs	D,y,x
	lda   	#$01           	; Flag drive motor is up to speed
        IFEQ  	Level-1
        sta   	>D.DskTmr
        ELSE
        sta   	<D.MotOn
        ENDC

	ldx   	#$0001         	; Install VIRQ entry
        leay  	>VIRQPak,u      ; Point to packet
        clr   	Vi.Stat,y      	; Reset Status byte
        ldd   	>VIRQCnt,pc    	; Get initial VIRQ count value
        os9   	F$VIRQ         	; Install VIRQ
        bcs  	VIRQOut        	; Error, exit
	inc	VIRQInstalled,u	; Flag it's installed
VIRQOut puls	X,Y,D
        rts   

* IRQ service routine for VIRQ (drive motor time)
* Entry: U=Ptr to VIRQ memory area
IRQSvc  pshs  	a
	lda   	<D.DMAReq
        beq   	L0509
        bsr   	InsVIRQ
        bra   	IRQOut
L0509    
	IFNE	DragonAlpha
	lbsr	AlphaDskCtl
	ELSE
        sta   	>DskCtl
	ENDC

        clr   	u00B5,u
	clr	VIRQInstalled,u
        IFEQ  	Level-1
        clr   	>D.DskTmr
        ELSE
        clr   	<D.MotOn
        ENDC
IRQOut  puls  	pc,a

		 
FDCCmd
	bsr   	FDCCmdMotorOn

; Delay routine !
Delay   lbsr  	Delay2
Delay2  lbsr  	Delay3
Delay3  rts   

* SetStat
*
* Entry:
*    A  = function code
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
SetStat ldx   	PD.Rgs,y	; Retrieve request
        ldb   	R$B,x
		 
        cmpb  	#SS.Reset	; Restore to track 0.
        beq   	ResetTrack0
        cmpb  	#SS.Wtrk	; Write (format) a track
        beq   	DoWriteTrack
        comb  
        ldb   	#E$UnkSvc
SetStatEnd    
	rts   
;
; Write (format) a track
;

DoWriteTrack    
	lbsr  	SelectDrive	; Select drive
        lda   	R$Y+1,x
        LBSR  	SetSide		; Set Side 2 if appropriate
        LDA   	R$U+1,X 
        BSR   	SetWPC         	; Set WPC by disk type

;L02D5
	ldx   	>CDrvTab,u
        lbsr  	SeekTS		; Move to correct track
        bcs   	SetStatEnd
        ldx   	PD.Rgs,y
        ldx   	R$X,x		
        ldb   	#WtTkCmnd
        pshs  	y,dp,cc
        lbra  	WriteTrackCmd
		 
; Reset track 0
ResetTrack0
	lbsr  	SelectDrive	; Select drive
        ldx   	>CDrvTab,u
        clr   	<V.Trak,x	; Set current track as 0
        lda   	#$05
ResetTrack0Loop    
	ldb   	#StpICmnd	; Step away from track 0 5 times
        pshs  	a
        lbsr  	FDCCommand
        puls  	a
        deca  
        bne   	ResetTrack0Loop
        ldb   	#RestCmnd	; Now issue a restore
        lbra  	FDCCommand
;
;Start drive motors
;

StartMotor    
	pshs  	x,b,a
        lda   	>D.DskTmr	; if timer <> 0 then skip as motor already on
        bne   	MotorsRunning				
        lda   	#MotorOn	; else spin up
		 
        IFNE	DragonAlpha
	bsr	AlphaDskCtl
	ELSE
        sta   	>DskCtl
	ENDC
	 
	ldx   	#$A000		; Wait a little while for motors to get up to speed
StartMotorLoop    
	nop   
        nop   
        leax  	-1,x
        bne   	StartMotorLoop
		 
MotorsRunning
	lbsr	SetupVIRQ
;	lda   	#$F0		; Start external motor timer
;        sta   	>D.DskTmr	; external to driver
        puls  	pc,x,b,a
	
;
; Set Write Precompensation according to media type
;

SetWPC  PSHS  	A,B 
        LDB   	PD.DNS,Y 
        BITB  	#T80Mask      	; Is it 96 tpi drive
        BNE   	SetWP1 
        ASLA                    ; no then double
SetWP1  CMPA  	#32		; WPC needed ?
        BLS   	SetWP2 
        LDA   	>DrivSel,U 
        ORA   	#WPCEn 
        STA   	>DrivSel,U 
SetWP2  PULS  	A,B,PC 


	IFNE	DragonAlpha

; Translate DragonDos Drive select mechinisim to work on Alpha 
; Takes byte that would be output to $FF48, reformats it and 
; outputs to Alpha AY-8912's IO port, which is connected to 
; Drive selects, motor on and enable precomp.
; This code now expects Alpha NMI/DDEN etc codes, as defined
; at top of this file (and dgndefs). The exception to this is
; the drive number is still passed in the bottom 2 bits and
; converted with a lookup table.
; We do not need to preserve the ROM select bit as this code
; operates in RAM only mode.
; Also sets NMIFlag.


DrvTab	FCB		Drive0A,Drive1A,Drive2A,Drive3A

AlphaDskCtl	
	PSHS	x,A,B,CC

	PSHS	A	
	ANDA	#NMIEn		; mask out nmi enable bit
	sta	>NMIFlag,u	; Save it for later use
		
	lda	,s		; Convert drives
	anda	#%00000011	; mask out drive number
	leax	DrvTab,pcr	; point at table
	lda	a,x		; get bitmap
	ldb	,s
	andb	#%11111100	; mask out drive number
	stb	,s
	ora	,s		; recombine
	sta	,s

	bita	#MotorOn	; test motor on ?
	bne	MotorRunning

	clra			; No, turn off other bits.
MotorRunning
	anda	#Mask58		; Mask out 5/8 bit to force the use of 5.25" clock
	sta	,s	
		
	lda	#AYIOREG	; AY-8912 IO register
	sta	PIA2DB		; Output to PIA
	ldb	#AYREGLatch	; Latch register to modify
	stb	PIA2DA
		
	clr	PIA2DA		; Idle AY
		
	lda	,s+		; Fetch saved Drive Selects
	sta	PIA2DB		; output to PIA
	ldb	#AYWriteReg	; Write value to latched register
	stb	PIA2DA		; Set register

	clr	PIA2DA		; Idle AY
			
	PULS	x,A,B,CC
	RTS

	ENDC
	

        emod
eom     equ   *
        end
