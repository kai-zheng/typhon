!------------------------------------------------------------------------------!
! Procedure : integration_ns_ust                     Authors : J. Gressier
!                                                    Created : July 2004
! Fonction  
!   Integration d'un domaine non structure
!   Le corps de la routine consiste a distribuer les etats et les gradients
!   sur chaque face.
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine integration_ns_ust(defsolver, defspat, domaine, field, flux, &
                              calc_jac, jacL, jacR)

use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_SOLVER
use MENU_NUM
use USTMESH
use DEFFIELD
use EQNS
use MATRIX_ARRAY

implicit none

! -- Declaration des entrees --
type(mnu_solver) :: defsolver        ! type d'equation a resoudre
type(mnu_spat)   :: defspat          ! parametres d'integration spatiale
type(st_ustmesh) :: domaine          ! domaine non structure a integrer
logical          :: calc_jac         ! choix de calcul de la jacobienne

! -- Declaration des entrees/sorties --
type(st_field)   :: field            ! champ des valeurs et residus

! -- Declaration des sorties --
type(st_genericfield)   :: flux        ! flux physiques
type(st_mattab)         :: jacL, jacR  ! jacobiennes associees (gauche et droite)

! -- Declaration des variables internes --
logical :: gradneeded           ! use gradients or not
integer :: if, nfb              ! index de face et taille de bloc courant
integer :: nbuf                 ! taille de buffer 
integer :: ib, nbloc            ! index de bloc et nombre de blocs
integer :: ideb, ifin           ! index de debut et fin de bloc
integer :: it                   ! index de tableau
integer :: icl, icr             ! index de cellule a gauche et a droite
type(st_nsetat)       :: cell_l, cell_r       ! tableau de cellules a gauche et a droite
type(st_genericfield) :: gradL, gradR         ! block size arrays of gradients
type(v3d), dimension(:), allocatable &
                      :: cg_l, cg_r           ! tableau des centres de cellules a gauche et a droite   

! -- BODY --

! On peut ici decouper la maillage complet en blocs de taille fixe pour optimiser
! l'encombrement memoire et la vectorisation

call calc_buffer(domaine%nface, cell_buffer, nbloc, nbuf, nfb)

! il sera a tester l'utilisation de tableaux de champs generiques plut�t que
! des definitions type d'etat specifiques (st_nsetat)

call new(cell_l, nbuf)
call new(cell_r, nbuf)
allocate(  cg_l(nbuf),   cg_r(nbuf))
call new(gradL, nbuf, field%gradient%nscal, field%gradient%nvect, field%gradient%ntens)
call new(gradR, nbuf, field%gradient%nscal, field%gradient%nvect, field%gradient%ntens)

ideb = 1

do ib = 1, nbloc

  select case(defspat%method)

  case(hres_none)

    do it = 1, nfb
      if  = ideb+it-1
      icl = domaine%facecell%fils(if,1)
      icr = domaine%facecell%fils(if,2)
      cell_l%density(it)  = field%etatprim%tabscal(1)%scal(icl)
      cell_r%density(it)  = field%etatprim%tabscal(1)%scal(icr)
      cell_l%pressure(it) = field%etatprim%tabscal(2)%scal(icl)
      cell_r%pressure(it) = field%etatprim%tabscal(2)%scal(icr)
      cell_l%velocity(it) = field%etatprim%tabvect(1)%vect(icl)
      cell_r%velocity(it) = field%etatprim%tabvect(1)%vect(icr)
    enddo
  
  ! - l'acces au tableau flux n'est pas programme de maniere generale !!! DEV

  !----------------------------------------------------------------------
  ! HIGH ORDER states interpolation
  !----------------------------------------------------------------------
  case(hres_muscl)

    call hres_ns_muscl(defspat, nfb, ideb, domaine,      &
                       field%etatprim, field%gradient,   &
                       cell_l, cell_r)

  case(hres_musclfast)

    call hres_ns_musclfast(defspat, nfb, ideb, domaine,      &
                           field%etatprim, field%gradient,   &
                           cell_l, cell_r)

  case(hres_muscluns)

    call hres_ns_muscluns(defspat, nfb, ideb, domaine,      &
                          field%etatprim, field%gradient,   &
                          cell_l, cell_r)

   case default
    call erreur("flux computation","unknown high resolution method")
  endselect

  !----------------------------------------------------------------------
  ! computation of INVISCID fluxes
  !----------------------------------------------------------------------

  ifin = ideb+nfb-1

  select case(defspat%sch_hyp)
  case(sch_ausmm)
    call calc_flux_ausmm(defsolver, defspat,                            &
                        nfb, domaine%mesh%iface(ideb:ifin, 1, 1),       &
                        cell_l, cell_r, flux, ideb,                     &
                        calc_jac, jacL, jacR)
  case(sch_hlle)
    call calc_flux_hlle(defsolver, defspat,                             &
                        nfb, domaine%mesh%iface(ideb:ifin, 1, 1),       &
                        cell_l, cell_r, flux, ideb,                     &
                        calc_jac, jacL, jacR)
  case(sch_hllc)
    call calc_flux_hllc(defsolver, defspat,                             &
                        nfb, domaine%mesh%iface(ideb:ifin, 1, 1),       &
                        cell_l, cell_r, flux, ideb,                     &
                        calc_jac, jacL, jacR)
  case default
    call erreur("error","numerical scheme not implemented (flux computation)")
  endselect

  !----------------------------------------------------------------------
  ! computation of VISCOUS fluxes
  !----------------------------------------------------------------------
  select case(defsolver%defns%typ_fluid)

  case(eqEULER)
    ! nothing to do

  case(eqNSLAM)

    ! -- redirection of cell centers 
    cg_l(1:nfb) = domaine%mesh%centre(domaine%facecell%fils(ideb:ifin,1), 1, 1)
    cg_r(1:nfb) = domaine%mesh%centre(domaine%facecell%fils(ideb:ifin,2), 1, 1)

    ! -- redirection of gradients
    call distrib_field(field%gradient, domaine%facecell, ideb, ifin, &
                       gradL, gradR, 1)
    call calc_flux_viscous(defsolver, defspat,                        &
                           nfb, ideb, domaine%mesh%iface(ideb:ifin, 1, 1), &
                           cg_l, cg_r,                                &
                           cell_l, cell_r, gradL, gradR, flux,        &
                           calc_jac, jacL, jacR)
  case(eqRANS)
    call erreur("development", "turbulence modeling not implemented")   

  case default
    call erreur("viscous flux computation", "unknown model")
  endselect

  !----------------------------------------------------------------------
  ! end of block

  ideb = ideb + nfb
  nfb  = nbuf         ! tous les blocs suivants sont de taille nbuf
  
enddo

!-------------------------------------------------------------
! flux assignment or modification on boundary conditions

call ns_bocoflux(defsolver, domaine, flux, field, defspat)

call delete(cell_l)
call delete(cell_r)
deallocate(cg_l, cg_r)
call delete(gradL)
call delete(gradR)

endsubroutine integration_ns_ust

!------------------------------------------------------------------------------!
! Changes history
!
! july 2004 : created, basic calls
! nov  2004 : high order interpolation
! feb  2005 : call to viscous flux computation
!------------------------------------------------------------------------------!
