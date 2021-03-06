!------------------------------------------------------------------------------!
! Procedure : integration  
!
! Fonction 
!   Full integration of all cycles and zones
!
!------------------------------------------------------------------------------!
subroutine integration(lworld)

use TYPHMAKE
use STRING
use TIMER
use OUTPUT
use VARCOM
use MODWORLD
use GRID_CONNECT

implicit none

! -- Inputs/Outputs --
type(st_world) :: lworld

! -- Internal variables --
type(st_grid), pointer :: pgrid
real(krp)              :: curtime, cputime, realtime, speedup, nopara
integer, dimension(:), allocatable &
                       :: exchcycle ! indices des cycles d'echange pour les differents couplages de zones
integer                :: icputimer, irealtimer
integer                :: ir, izone, ic, ierr
integer                :: iz1, iz2, ncoupl1, ncoupl2, nbc1, nbc2

! -- Body --

! initialization

lworld%info%icycle           = 0
lworld%info%curtps           = 0._krp
lworld%info%residu_ref       = 1._krp
lworld%info%cur_res          = lworld%info%residu_ref
lworld%info%stop_integration = .false.

! Allocation du tableau des indices de cycle d'echange pour les calculs couples
allocate(exchcycle(lworld%prj%ncoupling))
exchcycle(:) = 1 ! initialisation a 1 : 1er echange au 1er cycle, a partir des conditions initiales

! initialization

do izone = 1, lworld%prj%nzone
  lworld%zone(izone)%info%iter_tot   = 0
  lworld%zone(izone)%info%time_model = lworld%prj%time_model
enddo

icputimer  = cputime_start()
irealtimer = realtime_start()

!--------------------------------------------------------
! INTEGRATION
!--------------------------------------------------------
do while (.not. lworld%info%stop_integration)

  lworld%info%icycle = lworld%info%icycle + 1

  ! -- ecriture d'informations en debut de cycle --

  select case(lworld%prj%time_model)
  case(time_steady)
    str_w = "* CYCLE "//strof(lworld%info%icycle)
    !write(str_w,'(a,a)') "* CYCLE ",strof(lworld%info%icycle,3)
  case(time_unsteady, time_unsteady_inverse)
    write(str_w,'(a,i5,a,g11.4)') "* CYCLE", lworld%info%icycle, &
                                  " : t = ",  lworld%info%curtps
  !case(periodique)
  !  write(str_w,'(a,i5)') "* CYCLE", lworld%info%icycle
  case default
    call error_stop("internal error (integration): unknown time model")
  endselect

  call print_info(6,str_w)

  !--------------------------------------------------------
  ! cycle integration of all zones

  select case(lworld%prj%time_model)
  case(time_steady, time_unsteady)
    call integration_cycle(lworld, exchcycle, lworld%prj%ncoupling)
  case(time_unsteady_inverse)
    call integration_cycle_inverse(lworld, exchcycle, lworld%prj%ncoupling)
  case default
    call error_stop("internal error (integration): unknown time model")
  endselect

  ! -- Actualisation des conditions aux limites au raccord
  do ic = 1, lworld%prj%ncoupling
    call calcul_raccord(lworld, ic, iz1, iz2, ncoupl1, ncoupl2, nbc1, nbc2)
    call update_couplingboco(lworld%zone(iz1), lworld%zone(iz2), nbc1, nbc2, &
                             ncoupl1, lworld%coupling(ic)%boco)
  enddo

  ! -- ecriture d'informations en fin de cycle --

  select case(lworld%prj%time_model)

  case(time_steady)
    write(str_w,'(a,g11.4)') "  Residue in cycle = ", log10(lworld%info%cur_res/lworld%info%residu_ref)
    if (lworld%info%cur_res/lworld%info%residu_ref <= lworld%prj%residumax) then
      lworld%info%stop_integration = .true.
    endif
    if (lworld%info%icycle == lworld%prj%ncycle) then
      lworld%info%stop_integration = .true.
      write(uf_stdout,'(a)')   " Maximum number of cycles reached"
      write(uf_log,'(a,g11.4)') "Maximum number of cycles reached, RESIDUE = ",&
                           log10(lworld%info%cur_res/lworld%info%residu_ref)
    endif
    call print_info(6,str_w)

  case(time_unsteady, time_unsteady_inverse)
    lworld%info%curtps = lworld%info%curtps + lworld%prj%dtbase
    if (lworld%info%icycle == lworld%prj%ncycle) lworld%info%stop_integration = .true.

  case default
    call error_stop("Development: unknown TIME integration model")
  endselect

  !--------------------------------------------------------
  ! Outputs

  do izone = 1, lworld%prj%nzone
    call write_monitors_cycle(lworld%info, lworld%zone(izone))
    call write_bocohisto(     lworld%info, lworld%zone(izone))
  enddo

  call output_result(lworld, end_cycle)
  !--------------------------------------------------------

  open(unit=2001, file="typhon_stop", status="old", iostat=ierr)
  if (ierr == 0) then
    lworld%info%stop_integration = .true.
    call print_info(9, "INTERRUPTING INTEGRATION...")
    close(2001, status='delete')
  endif

enddo
!--------------------------------------------------------
! END OF INTEGRATION
!--------------------------------------------------------

cputime  = cputime_stop(icputimer)
realtime = realtime_stop(irealtimer)

write(str_w, "(a,e13.4)") "user  integration time: ", realtime
call print_info(10, str_w)
write(str_w, "(a,e13.4)") "CPU   integration time: ", cputime
call print_info(10, str_w)
write(str_w, "(a,e13.4)") "CPU average cycle time: ", cputime/lworld%info%icycle
call print_info(10, str_w)
if ((omp_run).and.(nthread>1)) then
  speedup  = cputime/realtime
  nopara   = (nthread-speedup)/speedup/(nthread-1)
  write(str_w, "(a,f5.2,a,f5.2,a)")  "              speed-up:",speedup," (",nopara*100,"% non parallel)"
  call print_info(10, str_w)
endif
do izone = 1, lworld%prj%nzone
  write(str_w, "(a,i7)") "Total nb of iterations: ", lworld%zone(izone)%info%iter_tot
  call print_info(10, str_w)
enddo

! Mise a jour des variables primitives

do izone = 1, lworld%prj%nzone
  call calc_varprim(lworld%zone(izone)%defsolver, lworld%zone(izone)%gridlist%first%info%field_loc)
enddo

! Mise a jour des conditions aux limites, notamment de couplage pour l'affichage des donnees :

if (lworld%prj%ncoupling > 0) then
  do ir = 1, lworld%prj%ncoupling
      call calcul_raccord(lworld, ir, iz1, iz2, ncoupl1, ncoupl2, nbc1, nbc2)
      call echange_zonedata(lworld,ir, iz1, iz2, ncoupl1, ncoupl2, nbc1, nbc2)
  enddo
endif

!do izone = 1, lworld%prj%nzone
!
! curtime = lworld%zone(izone)%info%cycle_start + lworld%zone(izone)%info%cycle_time
!
! pgrid => lworld%zone(izone)%gridlist%first
!
! do while(associated(pgrid))
!
!   call calcboco_connect(     lworld%zone(izone)%defsolver, lworld%zone(izone)%defsolver%defspat, pgrid, bccon_cell_state)
!   call calcboco_ust(curtime, lworld%zone(izone)%defsolver, lworld%zone(izone)%defsolver%defspat, pgrid)
!   pgrid => pgrid%next
!
! enddo
!
!enddo

!-----------------------------------------------------------------------------------------------------------------------
! DVT : Fermeture du fichier de comparaison des flux a l'interface
!-----------------------------------------------------------------------------------------------------------------------
!if (lworld%prj%ncoupling > 0) then
  close(uf_compflux)
!endif
!-----------------------------------------------------------------------------------------------------------------------

! Desallocation du tableau d'indice de cycle d'echange pour le calcul couple :
deallocate(exchcycle)

do izone = 1, lworld%prj%nzone
 select case(lworld%zone(izone)%defsolver%typ_solver)    ! DEV : en attendant homogeneisation
 case(solKDIF)                                           ! de l'acces des champs dans
   call dealloc_res(lworld%zone(izone)%gridlist%first%info%field_loc)       ! les structures MGRID
   call dealloc_cellgrad(lworld%zone(izone)%gridlist%first%info%field_loc)
 case(solVORTEX)
 endselect
enddo

endsubroutine integration

!------------------------------------------------------------------------------!
! Changes history
!
! Jul 2002: creation
! Jun 2003: instant d'echange excht
!           mise a jour des CL pour le fichier de sortie
! Sep 2003: gestion du calcul par residus (optionnel) + reorganisation
! Oct 2003: remplacement d'instant d'echange excht par indice de cycle d'echange
!           exchcycle
! Apr 2004: integration des structures MGRID pour tous les solveurs
! Oct 2004: field chained list
! Nov 2005: add ending cycle output
! Feb 2007: English translation
!------------------------------------------------------------------------------!
