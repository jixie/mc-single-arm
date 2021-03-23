      subroutine cryocylinder(z,th,rad_len,targlen,musc_len)
      implicit none
c calculate radiation length traversed by scattered particle
c cell = cylinder of radius 3.37 cm with flat endcap
      real*8 z,th,rad_len,targlen
      real*8 musc_len

      if( ((targlen/2.0-z)/cos(th) .lt. 3.37/sin(th)).and.
     > ( (targlen/2.0+z)/cos(th) .gt. 3.37/sin(th)) ) then
c scatters through end of cell
         musc_len = abs(targlen/2.0-z)/rad_len/cos(th)
         musc_len = musc_len + 0.005*2.54/8.89/cos(th)
      else
c goes through side
         musc_len = 3.37/rad_len/sin(th)
         musc_len = musc_len + 0.005*2.54/8.89/sin(th)
      endif

      return
      end
***************************************************************        
      subroutine cryotuna(ztar,th,rad_len,targlen,musc_len)
      implicit none
C Adapted from "tunatarg" in externals_all
C Inputs
      real*8 ztar,th,rad_len,targlen
C Output
      real*8 musc_len
C
      real*8 R,R1,zmax,zmin,ctan,ctan2,a,b,c
      real*8 thick
      real*8 xint,zint,zdiff,wall_cm,cryo_cm,lf(2)

      integer i

      thick = 0.005*2.54
      R1 = targlen/2.
      
      zmax =  targlen/2 - 1.e-4
      zmin = -targlen/2 + 1.e-4
      if(ztar.GT.zmax) ztar = zmax  !!! don't go outside target wall  !!!
      if(ztar.lt.zmin) ztar = zmin  !!! don't go outside target wall  !!!

      ctan = tan(th)
      ctan2 = ctan*ctan
      a = 1. + ctan2
      b = -2.*ztar*ctan2
     
      do i=1,2      !!!  Loop over inner and outer radius of cell wall  !!!
       R = R1
       if(i.eq.2) R = R1 + thick
       c = ztar*ztar*ctan2 - R*R
!!! z intersection of line and circle !!!
       zint = ((-1.)*b + sqrt(b*b - 4.*a*c))/2./a 
       if((R*R-zint*zint).ge.0.0) then
!!! x intersection of line and circle     !!! 
          xint = sqrt(R*R - zint*zint) 
       else
          xint = 0.0
       endif
       zdiff = zint - ztar      !!! z distance transversed                !!!  
       lf(i) = sqrt(xint*xint + zdiff*zdiff) !!!  total distance transversed  !!!
      enddo

      wall_cm = lf(2) - lf(1)
      cryo_cm = lf(1)

      musc_len = cryo_cm/rad_len + wall_cm/8.89
      return
      end

***************************************************************        
      subroutine cryotarg2017(z,th,rad_len,targlen,musc_len)
      implicit none
C calculate radiation length traversed by scattered particle
C Target geometry for 10 cm LH2 and LD2 (2017 cells)
C Taken from Abel Sun's calc for "externals"
C Inputs:
      real*8 z       ! z position in target
      real*8 th      ! scattering angle (radians)
      real*8 rad_len ! radiation length of target in cm
      real*8 targlen ! full length of target in cm
C Cell properties
      real*8 ecir,ecor,entec
      real*8 twall
C calculated stuff
      real*8 tcm,tliquid,tal
C Output:
      real*8 musc_len ! radiation length traversed by scattered particle

C This cell is a cylinder with a round end cap. Wall thickness = 5 mil
C Some dimensions are hardwired for now (or forever...).
      ecir=1.315*2.54           ! endcap inner radius (cm)
      ecor=1.320*2.54           ! endcap outer radius (cm)
c      targlen=3.942*2.54        ! target length (cm)
      entec=targlen-ecir        ! entrance to end cap (cm)

      twall = (ecor-ecir)/8.89    ! rad length of Al wall

      tcm=z+targlen/2.0         !length of target already traversed in cm

        if((tcm+ecir/tan(th)).lt.entec) then  ! e goes through sidewall
          tliquid=ecir/sin(th)/rad_len   ! liquid target
          tal=twall/sin(th)            ! wall material
        else
          tliquid=                              ! e goes throught end cap
     >     (sqrt(ecir**2-((targlen-ecir-tcm)*sin(th))**2)
     >    +(targlen-ecir-tcm)*cos(th))/rad_len ! liquid target

          tal=                           ! wall
     >    +(sqrt(ecor**2-((targlen-ecir-tcm)*sin(th))**2)
     >    -sqrt(ecir**2-((targlen-ecir-tcm)*sin(th))**2))
     >    *twall/(ecor-ecir)                   ! & end cap
        endif

        musc_len = tliquid+tal

        return
        end
***************************************************************        
c Added by Jixie for polorized he3 target, no target chamber 
c ignorring particle's raster position, assume it is 0 
      subroutine he3targ2019(z,th,rad_len,targlen,musc_len)
      implicit none
C calculate radiation length traversed by scattered particle
C Target geometry for 40 cm long He3 gas cell
C Inputs:
      real*8 z       ! z position in target
      real*8 th      ! scattering angle (radians)
      real*8 rad_len ! radiation length of target in cm
      real*8 targlen ! full length of target in cm
C Cell properties
      real*8 ecir,ecor,entec
      real*8 twall
C calculated stuff
      real*8 tcm,tgas,tal
C Output:
      real*8 musc_len ! radiation length traversed by scattered particle

C This cell is a cylinder with a round end. Wall thickness = 1.5 mm
C The window thickness is about 0.14 mm
C Some dimensions are hardwired for now (or forever...).
      ecir=0.87*2.54           ! endcap inner radius (cm)
      ecor=ecor+0.014          ! endcap outer radius (cm)
      
      entec=targlen-ecir       ! entrance to end cap (cm)

      twall = 0.15/7.04        ! rad length of GE180 wall is 7.04 cm
      tcm=z+targlen/2.0        ! length of target already traversed in cm

      if((tcm+ecir/tan(th)) .lt. entec) then  ! e goes through sidewall
          tgas=ecir/sin(th)/rad_len   ! rad length of gaseous target the particle will go thru
          tal=twall/sin(th)           ! wall material the particle will go thru
        else  ! e goes throught end cap
          tgas=                          ! gas   
     >     (sqrt(ecir**2-((targlen-ecir-tcm)*sin(th))**2)
     >    +(targlen-ecir-tcm)*cos(th))/rad_len ! gaseous target

          tal=                           ! wall
     >    +(sqrt(ecor**2-((targlen-ecir-tcm)*sin(th))**2)
     >    -sqrt(ecir**2-((targlen-ecir-tcm)*sin(th))**2))
     >    *twall/(ecor-ecir)             ! & end cap
        endif

C outside the target cell, there is about 44cm helium4 gas and ~2mm nylon helium bag
C the rad. length of nylon is about 35.0cm 
        musc_len = tgas+tal + 44./5.671E5 + 0.2/35.0 

        return
        end
***************************************************************        
