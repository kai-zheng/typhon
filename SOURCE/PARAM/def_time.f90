!------------------------------------------------------------------------------!
! Procedure : def_time                    Auteur : J. Gressier
!                                         Date   : Novembre 2002
! Fonction                                Modif  : (cf historique)
!   Traitement des parametres du fichier menu principal
!   Parametres d'integration temporelle
!
!------------------------------------------------------------------------------!
subroutine def_time(prj, block, solver, deftime)

use VARCOM
use RPM
use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_GEN
use MENU_NUM
use SPARSE_MAT

implicit none

! -- INPUTS --
type(mnu_project)      :: prj
type(rpmblock), target :: block
integer                :: solver

! -- OUTPUTS --
type(mnu_time) :: deftime

! -- Internal variables --
type(rpmblock), pointer  :: pblock, pcour  ! pointeur de bloc RPM
integer                  :: nkey           ! nombre de clefs
character(len=dimrpmlig) :: str            ! chaine RPM intermediaire

! -- BODY --

call print_info(5,"- Definition of time integration parameters")

! -- Recherche du BLOCK:TIME_PARAM

deftime%time_model = prj%time_model
deftime%implicite%calc_jacobian = .false.

pblock => block
call seekrpmblock(pblock, "TIME_PARAM", 0, pcour, nkey)

if (nkey /= 1) call erreur("parameters parsing", &
                           "bloc TIME_PARAM inexistant ou surnumeraire")

! -- type de calcul du pas de temps, et parametre associes

call rpmgetkeyvalstr(pcour, "DTCALC", str, "STABILITY_CONDITION")
deftime%stab_meth = inull

if (samestring(str,"LOCAL_STABILITY_CONDITION")) deftime%stab_meth = loc_stab_cond
if (samestring(str,"STABILITY_CONDITION"))       deftime%stab_meth = stab_cond
if (samestring(str,"GIVEN"))                     deftime%stab_meth = given_dt

if (deftime%stab_meth == inull) &
  call erreur("parameters parsing","methode de calcul DTCALC inconnue")

select case(deftime%stab_meth)
case(given_dt)
  call print_info(7,"  . user defined time step")
  call rpmgetkeyvalreal(pcour, "DT", deftime%dt)
case(stab_cond, loc_stab_cond)
  call print_info(7,"  . time step defined by stability condition")
  select case(solver)
  case(solKDIF)
    call rpmgetkeyvalreal(pcour, "FOURIER", deftime%stabnb)
  case(solNS)
    call rpmgetkeyvalreal(pcour, "CFL",     deftime%stabnb)
    call rpmgetkeyvalreal(pcour, "CFL_MAX", deftime%stabnb_max, deftime%stabnb)
  case default
    call erreur("parameters parsing","solveur inconnu (definition temporelle)")
  endselect
endselect

! -- si stationnaire, critere d'arret --

call  rpmgetkeyvalreal(pcour, "RESIDUALS", deftime%maxres, prj%residumax)

call  rpmgetkeyvalint(pcour, "CYCLE_MAX_IT", deftime%cyclemaxit, huge(deftime%cyclemaxit))
call  rpmgetkeyvalint(pcour, "MAX_IT",       deftime%maxit,      huge(deftime%maxit))

! -- type de schema temporel --

call rpmgetkeyvalstr(pcour, "METHOD", str, "EXPLICIT")
deftime%tps_meth = inull

if (samestring(str,"EXPLICIT"))    deftime%tps_meth = tps_expl
if (samestring(str,"RK2"))         deftime%tps_meth = tps_rk2
if (samestring(str,"RK2-TVD"))     deftime%tps_meth = tps_rk2ssp
if (samestring(str,"RK2-SSP"))     deftime%tps_meth = tps_rk2ssp
if (samestring(str,"RK3-SSP"))     deftime%tps_meth = tps_rk3ssp
if (samestring(str,"RK4"))         deftime%tps_meth = tps_rk4
if (samestring(str,"RK25BB"))      deftime%tps_meth = tps_lsrk25bb
if (samestring(str,"LSRK25BB"))    deftime%tps_meth = tps_lsrk25bb
if (samestring(str,"RK26BB"))      deftime%tps_meth = tps_lsrk26bb
if (samestring(str,"LSRK26BB"))    deftime%tps_meth = tps_lsrk26bb
if (samestring(str,"RK12BS"))      deftime%tps_meth = tps_lsrk12bs
if (samestring(str,"LSRK12BS"))    deftime%tps_meth = tps_lsrk12bs
if (samestring(str,"RK13BS"))      deftime%tps_meth = tps_lsrk13bs
if (samestring(str,"LSRK13BS"))    deftime%tps_meth = tps_lsrk13bs
if (samestring(str,"IMPLICIT"))    deftime%tps_meth = tps_impl
if (samestring(str,"DUAL-TIME"))   deftime%tps_meth = tps_dualt

if (deftime%tps_meth == inull) &
  call error_stop("parameters parsing: unknown method "//trim(str))

select case(deftime%tps_meth)
!------------------------------------------------------
! EXPLICIT METHOD
!-------------------------------------------------------
case(tps_expl)
  call print_info(7,"  . EXPLICIT integration")

!------------------------------------------------------
! RUNGE-KUTTA METHODs
!-------------------------------------------------------
case(tps_rk2, tps_rk2ssp, tps_rk3ssp, tps_rk4, tps_lsrk25bb, tps_lsrk26bb, tps_lsrk12bs, tps_lsrk13bs)
  call print_info(7,"  . RUNGE-KUTTA integration: "//trim(str))
  call init_rungekutta(deftime%tps_meth, deftime%rk)

!------------------------------------------------------
! IMPLICIT METHOD
!-------------------------------------------------------
case(tps_impl)

  call print_info(7,"  . IMPLICIT integration")

  ! -- set default parameters according to solver --

  select case(solver)
  case(solKDIF)
    deftime%implicite%methode = alg_cgs
    deftime%implicite%storage = mat_dlu
  case(solNS)
    deftime%implicite%methode = alg_bicgstab
    deftime%implicite%storage = mat_bdlu
  case default
    call error_stop("internal error: unexpected solver for implicit method")
  endselect

  if (rpm_existkey(pcour, "INVERSION")) then
    deftime%implicite%methode = alg_undef
    call rpmgetkeyvalstr(pcour, "INVERSION", str)
    if (samestring(str,"LU"))           deftime%implicite%methode = alg_lu
    if (samestring(str,"JACOBI"))       deftime%implicite%methode = alg_jac
    if (samestring(str,"GAUSS-SEIDEL")) deftime%implicite%methode = alg_gs
    if (samestring(str,"GS"))           deftime%implicite%methode = alg_gs
    if (samestring(str,"SOR"))          deftime%implicite%methode = alg_sor
    if (samestring(str,"BICG"))         deftime%implicite%methode = alg_bicg
    if (samestring(str,"BICG-JACOBI"))  deftime%implicite%methode = alg_bicgpjac
    if (samestring(str,"CGS"))          deftime%implicite%methode = alg_cgs
    if (samestring(str,"BICGSTAB"))     deftime%implicite%methode = alg_bicgstab
    if (samestring(str,"GMRES"))        deftime%implicite%methode = alg_gmres
    if (samestring(str,"GMRESFREE"))    deftime%implicite%methode = alg_gmresfree
  endif

  select case(deftime%implicite%methode)
  case(alg_lu)
    ! no additional parameter
    call print_info(9,"    LU direct inversion")

  case(alg_jac)
    call print_info(9,"    Jacobi iterative inversion")
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it, 10_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-4_krp)

  case(alg_gs)
    call print_info(9,"    Gauss-Seidel iterative inversion")
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it, 10_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-4_krp)

  case(alg_sor)
    call print_info(9,"    Successive Over Relaxation iterative inversion (SOR)")
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",    deftime%implicite%max_it, 10_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES",   deftime%implicite%maxres, 1.e-4_krp)
    call rpmgetkeyvalreal(pcour, "OVERRELAX", deftime%implicite%overrelax, 1._krp)

  case(alg_bicg)
    call print_info(9,"    Bi-Conjugate Gradient iterative inversion (BiCG)")
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it, 10_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-4_krp)

  case(alg_bicgpjac)
    call print_info(9,"    Bi-Conjugate Gradient iterative inversion (BiCG) - Jacobi preconditioning")
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it, 10_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-4_krp)

  case(alg_cgs)
    call print_info(9,"    Conjugate Gradient Squared iterative inversion (CGS)")
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it, 10_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-4_krp)

  case(alg_bicgstab)
    call print_info(9,"    Bi-Conjugate Gradient Stabilized iterative inversion (BiCG-Stab)")
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it, 50_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-1_krp)

  case(alg_gmres)
    call print_info(9,"    Generalized Minimum Residual iterative inversion (GMRES)")
    call rpmgetkeyvalint (pcour, "NKRYLOV", deftime%implicite%nkrylov, 50_kip)
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it,  50_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-4_krp)

  case(alg_gmresfree)
    call print_info(9,"    Matrix-Free Generalized Minimum Residual iterative inversion (GMRES)")
    call rpmgetkeyvalint (pcour, "NKRYLOV", deftime%implicite%nkrylov, 50_kip)
    call rpmgetkeyvalint (pcour, "IMP_MAX_IT",  deftime%implicite%max_it, 50_kip)
    call rpmgetkeyvalreal(pcour, "INV_RES", deftime%implicite%maxres, 1.e-4_krp)
    deftime%implicite%storage = mat_none
    !call erreur("algebra","unavailable inversion method: "//trim(str))

  case default
    call error_stop("algebra: unknown inversion method: "//trim(str))
  endselect

  if (rpm_existkey(pcour, "STORAGE")) then
    deftime%implicite%storage = mat_undef
    call rpmgetkeyvalstr(pcour, "STORAGE", str)
    if (samestring(str,"DLU"))   deftime%implicite%storage = mat_dlu
    if (samestring(str,"BDLU"))  deftime%implicite%storage = mat_bdlu
    if (samestring(str,"CRS"))   deftime%implicite%storage = mat_crs
    if (samestring(str,"BCRS"))  deftime%implicite%storage = mat_bcrs
    if (samestring(str,"NONE"))  deftime%implicite%storage = mat_none
  endif

  if ( deftime%implicite%storage == mat_undef ) then
    call erreur("algebra","unknown storage method: "//trim(str))
  endif

  if ( deftime%implicite%methode == alg_gmresfree .AND. &
       deftime%implicite%storage /= mat_none ) then
    call print_info(1,"algebra: "//trim(str)//" storage method incompatible with Matrix-Free GMRES")
    call error_stop("         No (default) storage method or NONE required")
  endif

  if ( deftime%implicite%methode /= alg_gmresfree .AND. &
       deftime%implicite%storage == mat_none ) then
    call print_info(1,"algebra: "//trim(str)//" storage method incompatible without Matrix-Free GMRES")
    select case(solver)
    case(solKDIF)
      call error_stop("         Default (DLU) storage method or DLU required")
    case(solNS)
      call error_stop("         Default (BDLU) storage method or BDLU required")
    endselect
  endif

  deftime%implicite%calc_jacobian =  ( deftime%implicite%storage /= mat_none )

!------------------------------------------------------
! DUAL TIME METHOD
!-------------------------------------------------------
case(tps_dualt)
  call print_info(7,"  . DUAL TIME integration")

case default
  call error_stop("parameter parsing: unknown parameter for time integration (METHOD): "//trim(str))
endselect


endsubroutine def_time

!------------------------------------------------------------------------------!
! Changes history
! Nov 2002 : creation
! Sep 2003 : scan timestep parameters
! Apr 2004 : scan implicit parameters
! Oct 2009 : matrix-free GMRES
!------------------------------------------------------------------------------!
