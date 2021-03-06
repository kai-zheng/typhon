!------------------------------------------------------------------------------!
! Procedure : interp_facegradient_vect    Author : J. Gressier
!                                         Date   : March 2005
! Fonction                                Modif  : (cf history)
!   Compute an interpolated gradient at a face center from cell gradients
!   and cell values
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine interp_facegradient_vect(nf, meth, ndHL, ndHR, vLR, &
                                    qL, qR, dqL, dqR, dqH)

use OUTPUT
use PACKET
use MENU_NUM
use USTMESH
use GENFIELD

implicit none

! -- INPUTS --
integer                      :: nf         ! number of parsed faces
integer(kpp)                 :: meth       ! method for gradient interpolation
real(krp),     dimension(nf) :: ndHL       ! face center to left  center distance / (HL + HR)
real(krp),     dimension(nf) :: ndHR       ! face center to right center distance / (HL + HR)
type(v3d),     dimension(nf) :: vLR        ! left center to right center vector 
!
type(v3d), dimension(nf) ::  qL,  qR   ! left and right quantities (at cell centers)
type(t3d), dimension(nf) :: dqL, dQR   ! left and right gradients  (at cell centers)

! -- OUTPUTS --
type(t3d), dimension(nf) :: dqH        ! interpolated face gradients 


! -- Internal variables --
real(krp) :: dLR2(nf)
type(t3d) :: Favg, Fcomp
type(v3d) :: FavgLR(nf)
integer   :: if, k, icl, icr

real(krp) :: theta = 1._krp

! -- BODY --

if (nf > taille_buffer) then
  call error_stop("Development: interpolation should be used after splitting into packets")
endif

!--------------------------------------------------------------
! Choice of interpolation formulation
!--------------------------------------------------------------
! if Favg = (a.gT(L) + b.gT(R))
! COMPACT : F1 = (T(R) - T(L))            ! L & R cell centers ! NOT CONSISTENT: ERROR
! AVERAGE : F2 = (a.gT(L) + b.gT(R)).n    ! H face center
! FULL    : F3 = 
! a = HR/RL et b = HL/RL

select case(meth)

case(dis_celldif2) ! compact formulation, non consistent if vLR and (n) are not aligned

  call error_stop("gradient interpolation: non authorized method (interpface_gradient_vect)")

case(dis_cellavg2) ! consistent formulation, only weighted average of gradients

  do if = 1, nf
    dqH(if)  = (ndHL(if)*dqR(if) + ndHR(if)*dqL(if))
  enddo

case(dis_cellfull) ! full consistent formulation, averaged between compact and averaged formulations

  dLR2(1:nf) = sqrabs(vLR(1:nf))
  
  dqH(1:nf)    = ndHL(1:nf)*dqR(1:nf) + ndHR(1:nf)*dqL(1:nf)     ! compute F_average
  FavgLR(1:nf) = qR(1:nf) - qL(1:nf) - (dqH(1:nf).scal.vLR(1:nf))
  dqH(1:nf)    = dqH(1:nf) + ( FavgLR(1:nf).tens.((theta/dLR2(1:nf))*vLR(1:nf)) )

case default
  call error_stop("internal error: unknown gradient interpolation method (interpface_gradient_vect)")
endselect

!-----------------------------
endsubroutine interp_facegradient_vect

!------------------------------------------------------------------------------!
! Changes history
!
! mar  2005 : creation
!------------------------------------------------------------------------------!
