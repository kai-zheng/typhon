!------------------------------------------------------------------------------!
! Procedure : calc_varcons_kdif           Auteur : J. Gressier
!                                         Date   : Juin 2003
! Fonction                                Modif  : Juin 2003 (cf historique)
!   Calcul des variables conservatives a partir des variables primitives
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine calc_varcons_kdif(defkdif, field)

use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_SOLVER
use DEFFIELD

implicit none

! -- Declaration des entrees --
type(mnu_kdif) :: defkdif       ! definition des parametres du solveur

! -- Declaration des entrees/sorties --
type(st_field)   :: field       ! champ primitives->conservatives

! -- Declaration des variables internes --
integer :: ip

! -- Debut de la procedure --

do ip = 1, field%nscal
  select case(defkdif%materiau%type)
  case(mat_LIN, mat_KNL)
    field%etatcons%tabscal(ip)%scal(:) = defkdif%materiau%Cp &
                                       * field%etatprim%tabscal(ip)%scal(:) 
  case(mat_XMAT)
    call erreur("Calcul de materiau","Materiau non lineaire interdit")
  endselect
enddo


!-----------------------------
endsubroutine calc_varcons_kdif

!------------------------------------------------------------------------------!
! Historique des modifications
!
! juin 2003 (v0.0.1b): creation de la procedure
!------------------------------------------------------------------------------!
