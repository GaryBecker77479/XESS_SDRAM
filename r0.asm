********************************************************************
* FPGADSKdesc - FPGADSK Device Descriptor Template
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------

         nam   fpgadskdesc
         ttl   fpgadsk Device Descriptor Template

* Disassembled 98/08/23 17:09:41 by Disasm v1.6 (C) 1988 by RML

         ifp1  
         use   defsfile.txt
		 
		 
         endc  

tylg     set   Devic+Objct
atrv     set   ReEnt+rev
rev      set   $00

	IFNDEF	DNum
DNum     set   0
	ENDC
         IFNE  D35
Type     set   TYP.CCF+TYP.3
         ELSE
Type     set   TYP.CCF+TYP.5
         ENDC
	IFNDEF	Density
Density  set   DNS.MFM
	ENDC
Step     set   STP.6ms
	IFNDEF	Cyls
Cyls     set   35
	ENDC
	IFNDEF	Cyls_Hi
Cyls_Hi  set   0
	ENDC
Verify   set   1
	IFNDEF	SectTrk
SectTrk  set   18
	ENDC
	IFNDEF	SectTrk0
SectTrk0 set   18
	ENDC
	IFNDEF	Interlv
Interlv  set   3
	ENDC
	IFNDEF	SAS
SAS      set   8
	ENDC

         mod   eom,name,tylg,atrv,mgrnam,drvnam

         fcb   DIR.!SHARE.!PEXEC.!PWRIT.!PREAD.!EXEC.!UPDAT. mode byte
         fcb   HW.Page    extended controller address
         fdb   $FF40      physical controller address
         fcb   initsize-*-1 initalization table size
         fcb   DT.RBF     device type:0=scf,1=rbf,2=pipe,3=scf
         fcb   DNum       drive number
         fcb   Step       step rate
         fcb   Type       drive device type
         fcb   Density    media density:0=single,1=double
         fdb   Cyls       low number of cylinders (tracks)
         fcb   Cyls_Hi    high number of cylinders (tracks)
         fcb   Verify     verify disk writes:0=on
         fdb   SectTrk    # of sectors per track
         fdb   SectTrk0   # of sectors per track (track 0)
         fcb   Interlv    sector interleave factor
         fcb   SAS        minimum size of sector allocation
initsize equ   *

         IFNE  DD
name     fcs   /DD/
         ELSE
name     fcb   'D,'0+DNum+$80
         ENDC
mgrnam   fcs   /RBF/
drvnam   fcs   /fpgadsk/

         emod
eom      equ   *
         end
