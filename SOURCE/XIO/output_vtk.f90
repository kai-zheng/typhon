!------------------------------------------------------------------------------!
! Procedure : output_vtk                        Authors : J. Gressier
!                                               Created : April 2004
! Function
!   Write the field of each zone in a VTK file
!
!------------------------------------------------------------------------------!
 
subroutine output_vtk(nom, world, outp_typ, position, io) 

use TYPHMAKE
use OUTPUT
use VARCOM
use MODWORLD

implicit none

! -- INPUTS --
character(len=strlen) :: nom       ! nom du fichier
type(st_world)        :: world
integer               :: outp_typ
integer               :: position 
integer               :: io       !DEV2602

! -- OUPUTS --

! -- Internal variables --
integer               :: izone, i, dim, ufc, ir
integer               :: info
type(st_genericfield) :: vfield
character(len=10)     :: suffix

! -- BODY --

if (mpi_run) then
  suffix = "_p"//strof_full_int(myprocid,3)//".vtk"
else
  suffix = ".vtk"
endif

select case(position)
case(end_calc, end_cycle)

  if ((outp_typ == outp_NODE).or.(outp_typ == outp_CENTER)) then

    ! DEVELOPPEMENT PROVISOIRE
    open(unit=uf_chpresu, file=trim(nom)//trim(suffix), form='formatted', iostat = info)

    do izone = 1, world%prj%nzone

      select case(world%zone(izone)%defsolver%typ_solver)

      case(solNS)
        write(uf_chpresu,'(A)') '# vtk DataFile Version 2.0'
        write(uf_chpresu,'(A)') 'TYPHON-NS'
        write(uf_chpresu,'(A)') 'ASCII'
        call output_vtk_cell(uf_chpresu, world%zone(izone)%defsolver, &
                             world%zone(izone)%grid%umesh, world%zone(izone)%grid%info%field_loc)

      case(solKDIF)

        write(uf_chpresu,'(A)') '# vtk DataFile Version 2.0'
        write(uf_chpresu,'(A)') 'TYPHON-KDIF'
        write(uf_chpresu,'(A)') 'ASCII'
        call output_vtk_cell(uf_chpresu, world%zone(izone)%defsolver, &
                             world%zone(izone)%grid%umesh, world%zone(izone)%grid%info%field_loc)

      case(solVORTEX)

        call erreur("Developpement","les sorties VORTEX ne sont pas prevues dans ce format")

      case default

        call erreur("Developpement","solveur inconnu (output_vtk)")

      endselect

    enddo ! fin boucle : zone

    close(uf_chpresu)

  endif

case default
  print*,"!DEV! blanked output_vtk"
endselect

endsubroutine output_vtk
!------------------------------------------------------------------------------!
! Changes history
!
! avr  2004 : creation de la procedure
! oct  2004 : field chained list
! Oct  2005 : add suffix with proc number
!------------------------------------------------------------------------------!
