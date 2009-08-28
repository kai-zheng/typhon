!------------------------------------------------------------------------------!
! Procedure : write_monitors_iteration
!             
! Fonction    
!   Calcul des quantites definies par les write_monitors
!
!------------------------------------------------------------------------------!
subroutine write_monitors_iteration(zone)

use TYPHMAKE
use OUTPUT
use VARCOM
use DEFZONE
use MENU_GEN

implicit none

! -- Inputs --
type(st_zone) :: zone            ! zone

! -- Outputs --

! -- Internal variables --
integer    :: ic                 ! index de capteur

! -- BODY --

!!$do ic = 1, zone%defsolver%nprobe
!!$
!!$  select case(zone%defsolver%probe(ic)%type)
!!$  case(probe)
!!$    call erreur("Developpement","type PROBE non implemente")
!!$  case(boco_field)
!!$    call prb_boco_field(zone)
!!$  case(boco_integral)
!!$    call erreur("Developpement","type BOCO_INTEGRAL non implemente")
!!$  case(residuals)
!!$
!!$  endselect
!!$
!!$enddo

select case(zone%info%time_model)
case(time_steady)
  write(uf_monres,*) zone%info%iter_tot, log10(zone%info%cur_res)
endselect

!-----------------------------
endsubroutine write_monitors_iteration

!------------------------------------------------------------------------------!
! Changes history
!
! mai 2003 : creation de la procedure (test pour debuggage)
! nov 2003 : redirection selon type de capteur
! Apr 2008: change name into write_monitors.f90
! Jun 2009: change name into write_monitors_iteration.f90
!------------------------------------------------------------------------------!