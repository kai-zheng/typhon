!------------------------------------------------------------------------------!
! Procedure : hres_ns_svm
!                                
! Fonction
!   SVM interpolation of primitive quantities
!
!------------------------------------------------------------------------------!
subroutine hres_ns_svm(defspat, nf, ideb, umesh, fprim, cell_l, cell_r, ic0)

use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_NUM
use USTMESH
use GENFIELD
use EQNS
use GEO3D
use LIMITER

implicit none

! -- INPUTS --
type(mnu_spat)        :: defspat          ! parametres d'integration spatiale
integer               :: nf, ideb         ! face number and first index
type(st_ustmesh)      :: umesh            ! unstructured mesh definition
type(st_genericfield) :: fprim            ! primitive variables fields
integer(kip)          :: ic0              ! cell field offset

! -- OUTPUTS --
type(st_genericfield) :: cell_l, cell_r   ! champs des valeurs primitives

! -- Internal variables --
integer                   :: i, if, ic, isca, ivec, ig
integer                   :: isv, icv1, icv2, ncv
integer                   :: isvface
real(krp)                 :: weights(1:defspat%svm%ncv)

! -- BODY --


ncv = defspat%svm%ncv


    select case(defspat%svm%nfgauss)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!  SVM 2 : Only one Gauss point per CV face
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    case(1)
!------------------------------------------------------------------------------
! SCALAR interpolation
!------------------------------------------------------------------------------
do isca = 1, fprim%nscal

  do i = 1, nf      ! indirection loop on faces (index in packet)

    if = ideb-1+i                    ! (face index)
    ic = ic0 -1+i

    ! -- left side --

    isv  = (umesh%facecell%fils(if,1)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv
    do ig = 1, defspat%svm%nfgauss     ! loop on gauss points
      weights(1:ncv) = defspat%svm%interp_weights(umesh%face_Ltag%fils(if, ig), 1:ncv)
      cell_l%tabscal(isca)%scal(ic) = sum(weights(1:ncv) * fprim%tabscal(isca)%scal(icv1:icv2))
    enddo

    ! -- right side --

    isv  = (umesh%facecell%fils(if,2)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv

    if (umesh%face_Rtag%fils(if, 1) /= 0) then
       do ig = 1, defspat%svm%nfgauss     ! loop on gauss points
         weights(1:ncv) = defspat%svm%interp_weights(umesh%face_Rtag%fils(if, ig), 1:ncv)
         cell_r%tabscal(isca)%scal(ic) = sum(weights(1:ncv) * fprim%tabscal(isca)%scal(icv1:icv2))
       enddo
    else
      cell_r%tabscal(isca)%scal(ic) = fprim%tabscal(isca)%scal(umesh%facecell%fils(if,2))
    endif
  enddo

enddo

!------------------------------------------------------------------------------
! VECTOR interpolation
!------------------------------------------------------------------------------
do ivec = 1, fprim%nvect

  do i = 1, nf      ! indirection loop on faces (index in packet)

    if = ideb-1+i                    ! (face index)
    ic = ic0 -1+i

    ! -- left side --

    isv  = (umesh%facecell%fils(if,1)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv

    do ig = 1, defspat%svm%nfgauss     ! loop on gauss points
      weights(1:ncv) = defspat%svm%interp_weights(umesh%face_Ltag%fils(if, ig), 1:ncv)
      cell_l%tabvect(ivec)%vect(ic) = sum(weights(1:ncv) * fprim%tabvect(ivec)%vect(icv1:icv2))
    enddo

    ! -- right side --

    isv  = (umesh%facecell%fils(if,2)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv

    if (umesh%face_Rtag%fils(if, 1) /= 0) then
       do ig = 1, defspat%svm%nfgauss     ! loop on gauss points
         weights(1:ncv) = defspat%svm%interp_weights(umesh%face_Rtag%fils(if, ig), 1:ncv)
         cell_r%tabvect(ivec)%vect(ic) = sum(weights(1:ncv) * fprim%tabvect(ivec)%vect(icv1:icv2))
       enddo
    else
      cell_r%tabvect(ivec)%vect(ic) = fprim%tabvect(ivec)%vect(umesh%facecell%fils(if,2))
    endif

  enddo

enddo

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!  SVM 3 & 4: Two Gauss points per CV face
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    case(2)
!------------------------------------------------------------------------------
! SCALAR interpolation
!------------------------------------------------------------------------------

do isca = 1, fprim%nscal

  do i = 1, nf      ! indirection loop on faces (index in packet)

    if = ideb-1+i                    ! (face index)
    ic = ic0 -1+i

    ! -- left side --

    isv  = (umesh%facecell%fils(if,1)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv
      cell_l%tabscal(isca)%scal(ic) = .5_krp * &
(sum(defspat%svm%interp_weights(2*umesh%face_Ltag%fils(if, 1)-1, 1:ncv) * fprim%tabscal(isca)%scal(icv1:icv2))&
+ sum(defspat%svm%interp_weights(2*umesh%face_Ltag%fils(if, 1), 1:ncv) * fprim%tabscal(isca)%scal(icv1:icv2)))
    ! -- right side --
    isv  = (umesh%facecell%fils(if,2)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv

    if (umesh%face_Rtag%fils(if, 1) /= 0) then
         cell_r%tabscal(isca)%scal(ic) = .5_krp * &
(sum(defspat%svm%interp_weights(2*umesh%face_Rtag%fils(if, 1)-1, 1:ncv) * fprim%tabscal(isca)%scal(icv1:icv2))&
+ sum(defspat%svm%interp_weights(2*umesh%face_Rtag%fils(if, 1), 1:ncv) * fprim%tabscal(isca)%scal(icv1:icv2)))

    else
      cell_r%tabscal(isca)%scal(ic) = fprim%tabscal(isca)%scal(umesh%facecell%fils(if,2))
    endif
  enddo

enddo

!------------------------------------------------------------------------------
! VECTOR interpolation
!------------------------------------------------------------------------------
do ivec = 1, fprim%nvect

  do i = 1, nf      ! indirection loop on faces (index in packet)

    if = ideb-1+i                    ! (face index)
    ic = ic0 -1+i

    ! -- left side --
    isv  = (umesh%facecell%fils(if,1)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv
      cell_l%tabvect(ivec)%vect(ic) = .5_krp * &
(sum(defspat%svm%interp_weights(2*umesh%face_Ltag%fils(if, 1)-1, 1:ncv) * fprim%tabvect(ivec)%vect(icv1:icv2))&
+ sum(defspat%svm%interp_weights(2*umesh%face_Ltag%fils(if, 1), 1:ncv) * fprim%tabvect(ivec)%vect(icv1:icv2)))


    ! -- right side --
    isv  = (umesh%facecell%fils(if,2)-1) / ncv + 1
    icv1 = (isv-1)*ncv + 1
    icv2 = isv*ncv

    if (umesh%face_Rtag%fils(if, 1) /= 0) then
         cell_r%tabvect(ivec)%vect(ic) = .5_krp * &
(sum(defspat%svm%interp_weights(2*umesh%face_Rtag%fils(if, 1)-1, 1:ncv) * fprim%tabvect(ivec)%vect(icv1:icv2))&
+ sum(defspat%svm%interp_weights(2*umesh%face_Rtag%fils(if, 1), 1:ncv) * fprim%tabvect(ivec)%vect(icv1:icv2)))

    else
      cell_r%tabvect(ivec)%vect(ic) = fprim%tabvect(ivec)%vect(umesh%facecell%fils(if,2))
    endif

  enddo

enddo

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!  SVM Unknown
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    case default!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      call erreur("Internal Error","unknown SVM method")
    endselect
endsubroutine hres_ns_svm

!------------------------------------------------------------------------------!
! Changes history
! Mar  2008 : created, generic SVM interpolation (now only applied with svm2quad
!------------------------------------------------------------------------------!
