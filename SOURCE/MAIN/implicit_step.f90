!------------------------------------------------------------------------------!
! Procedure : implicit_step                            Auteur : J. Gressier
!                                                      Date   : Avril 2004
! Fonction
!   Implicit Integration of the domain
!
!------------------------------------------------------------------------------!
subroutine implicit_step(dt, typtemps, defsolver, defspat, deftime, &
                         umesh, field, coupling, ncp)

use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_SOLVER
use MENU_NUM
use USTMESH
use DEFFIELD
use MATRIX_ARRAY
use SPARSE_MAT
use MENU_ZONECOUPLING

implicit none

! -- Inputs --
real(krp)        :: dt         ! pas de temps CFL
character        :: typtemps   ! type d'integration (stat, instat, period)
type(mnu_solver) :: defsolver  ! type d'equation a resoudre
type(mnu_spat)   :: defspat    ! parametres d'integration spatiale
type(mnu_time)   :: deftime    ! parametres d'integration spatiale
type(st_ustmesh) :: umesh      ! domaine non structure a integrer
integer          :: ncp        ! nombre de couplages de la zone

! -- Input/output --
type(st_field)   :: field            ! champ des valeurs et residus
type(mnu_zonecoupling), dimension(1:ncp) &
                 :: coupling ! donnees de couplage

! -- Internal variables --
type(st_spmat)        :: mat
type(st_genericfield) :: flux             ! tableaux des flux
type(st_mattab)       :: jacL, jacR       ! tableaux de jacobiennes des flux
integer(kip)          :: if, ic1, ic2, ic, info, dim

! -- BODY --

call new(jacL, umesh%nface, defsolver%nequat)
call new(jacR, umesh%nface, defsolver%nequat)

!--------------------------------------------------
! phase explicite : right hand side computation
!--------------------------------------------------

! -- allocation des flux et termes sources --

call new(flux, umesh%nface, field%nscal, field%nvect, 0)

select case(defsolver%typ_solver)
case(solKDIF)
  call integration_kdif_ust(dt, defsolver, defspat, umesh, field, flux, .true., jacL, jacR)
case(solNS)
  call integration_ns_ust(dt, defsolver, defspat, umesh, field, flux, .true., jacL, jacR)
case default
  call erreur("internal error (implicit_step)", "unknown or unexpected solver")
endselect

! -- flux surfaciques -> flux de surfaces et calcul des residus  --

call flux_to_res(dt, umesh, flux, field%residu, .true., jacL, jacR)

!--------------------------------------------------
! build implicit system
!--------------------------------------------------

call build_implicit(dt, deftime, umesh, jacL, jacR, mat)

call delete(jacL)
call delete(jacR)

!--------------------------------------------------
! solve implicit system
!--------------------------------------------------

! CALL SOLVE IMPLICIT SYSTEM
! resolution

select case(deftime%implicite%methode)
case(alg_lu)
  call dlu_lu(mat, field%residu%tabscal(1)%scal, field%residu%tabscal(1)%scal)

case(alg_jac)
  call dlu_jacobi(deftime%implicite, mat%dlu, field%residu%tabscal(1)%scal, &
                  field%residu%tabscal(1)%scal, info)
  if (info < 0) call print_warning("methode d'inversion JACOBI non convergee")

case(alg_gs)
  call erreur("developpement","Methode Gauss-Seidel non implementee")

case(alg_sor)
  call erreur("developpement","Methode SOR non implementee")
  
case default
  call erreur("incoherence","methode d'inversion inconnue")
endselect

call delete(mat)

!--------------------------------------------------

!select case(typtemps)
! case(instationnaire) ! corrections de flux seulement en instationnaire

! ! Calcul de l'"energie" a l'interface, en vue de la correction de flux, pour 
! ! le couplage avec echanges espaces
! !DVT : flux%tabscal(1) !
! if (ncp>0) then
!   call accumulfluxcorr(dt, defsolver, umesh%nboco, umesh%boco, &
!                        umesh%nface, flux%tabscal(1)%scal, ncp, &
!                        coupling)
! endif

!endselect

if (ncp > 0) call erreur("Developpement","couplage interdit en implicite")

call delete(flux)


endsubroutine implicit_step
!------------------------------------------------------------------------------!
! Change History
!
! Apr  2004 : creation
! Aug  2005 : split / call build_system to handle different structures
!------------------------------------------------------------------------------!
