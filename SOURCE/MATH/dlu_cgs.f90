!------------------------------------------------------------------------------!
! Procedure : dlu_cgs                             Authors : J. Gressier
!                                                    Created : August 2005
! Fonction
!   Resolution of linear system : mat.sol = rhs
!     mat type(st_dlu)
!     non stationnary iterative method CGS 
!
! Defauts/Limitations/Divers :
!   - le tableau sol(*) est cense etre deja alloue
!   - la resolution passe par l'allocation d'une matrice pleine (dim*dim)
!
!------------------------------------------------------------------------------!
subroutine dlu_cgs(def_impli, mat, rhs, sol, info)

use TYPHMAKE
use SPARSE_MAT
use LAPACK
use MENU_NUM

implicit none

! -- Inputs --
type(mnu_imp) :: def_impli
type(st_dlu)  :: mat
real(krp)     :: rhs(1:mat%dim)

! -- Outputs --
real(krp)     :: sol(1:mat%dim)
integer(kip)  :: info

! -- Internal variables --
real(krp), dimension(:), allocatable :: r1, r2, p1, q1, u , v 
integer(kip)                         :: nit, ic, if, imin, imax, dim
real(krp)                            :: erreur, ref
real(krp)                            :: rho0, rho1, beta, alpha

! -- Debut de la procedure --

dim = mat%dim

! initialisation

nit    = 0
erreur = huge(erreur)    ! maximal real number in machine representation (to ensure 1st iteration)

allocate(r1(dim)) ;     allocate(r2(dim))
allocate(p1(dim))
allocate(q1(dim))
allocate(u (dim))
allocate(v (dim))
!allocate(soln(dim))

! -- initialization --

p1(1:dim) = rhs(1:dim)  ! SAVE RHS BECAUSE SOL CAN OVERWRITE RHS
sol(1:dim) = p1(1:dim) / mat%diag(1:dim)  ! initial guess
ref = sum(abs(sol(1:dim)))

!call sort_dlu(mat)

r1(1:dim) = - sol(1:dim)
call dlu_xeqaxpy(r1(1:dim), mat, p1(1:dim), r2(1:dim))    ! R1 = RHS - MAT.SOL
r2(1:dim) = r1(1:dim)                                     ! R2 = R1

do while ((erreur >= ref*def_impli%maxres).and.(nit <= def_impli%max_it))

  rho1 = dot_product(r1(1:dim), r2(1:dim))

  if (nit == 0) then
    u (1:dim) = r1(1:dim)
    p1(1:dim) = r1(1:dim)
  else
    beta = rho1 / rho0
    u (1:dim) = r1(1:dim) + beta*q1(1:dim)
    v (1:dim) = q1(1:dim) + beta*p1(1:dim)
    p1(1:dim) = u (1:dim) + beta*v (1:dim)
  endif
 
  call dlu_yeqax (v (1:dim), mat, p1(1:dim))
  alpha = rho1 / dot_product(r2(1:dim), v (1:dim))
  q1(1:dim) = u (1:dim) - alpha*v (1:dim) 

  v (1:dim) = u (1:dim) + q1(1:dim)

  ! error computation
  erreur  = abs(alpha)*sum(abs(v (1:dim)))
  sol(1:dim) = sol(1:dim) + alpha*v (1:dim)
  !print*,'conv cgs',nit,log10(erreur/ref), rho1

  ! prepare next iteration
  call dlu_yeqax (u (1:dim), mat, v (1:dim))
  r1(1:dim) = r1(1:dim) - alpha*u (1:dim) 
  rho0 = rho1
  
  nit     = nit + 1

enddo

if (nit > def_impli%max_it) then
  info = nit - 1
else
  info = -1
endif

deallocate(r1, r2, p1, q1, u, v)

endsubroutine dlu_cgs

!------------------------------------------------------------------------------!
! Changes history
!
! Aug  2005 : creation
!------------------------------------------------------------------------------!