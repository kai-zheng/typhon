!------------------------------------------------------------------------------!
! MODULE : GEO3D                          Auteur : J. Gressier
!                                         Date   : Mai 2002
! Fonction                                Modif  : (cf historique)
!   Bibliotheque de procedures et fonctions pour le calcul geometrique 3D
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!

module GEO3D

use TYPHMAKE
use GEO2D
use STRING

! -- DECLARATIONS -----------------------------------------------------------

type v3d
  real(krp) :: x, y, z
endtype

! -- INTERFACES -------------------------------------------------------------

interface v3d_of
  module procedure v3d_fromtab, v3d_fromv2d, v3d_fromstr
endinterface

interface tab
  module procedure tab_v3d
endinterface

interface abs
  module procedure v3d_norme
endinterface

interface sqrabs
  module procedure v3d_sqrnorme
endinterface

interface operator(+)
  module procedure v3d_addition
endinterface

interface operator(-)
  module procedure v3d_substraction, v3d_opp
endinterface

interface operator(*)
  module procedure v3d_multiplysp, v3d_multiplydp
endinterface

interface operator(/)
  module procedure v3d_divisionsp, v3d_divisiondp
endinterface

interface operator(.scal.)
  module procedure v3d_scalar_product
endinterface

interface operator(.vect.)
  module procedure v3d_vectorial_product
endinterface

! -- Fonctions et Operateurs ------------------------------------------------


! -- IMPLEMENTATION ---------------------------------------------------------
contains

!------------------------------------------------------------------------------!
! Fonction : transtypage real(1:3) -> v3d
!------------------------------------------------------------------------------!
type(v3d) function v3d_fromtab(tab)
implicit none
real(krp), dimension(3) :: tab

  v3d_fromtab = v3d(tab(1), tab(2), tab(3))

endfunction v3d_fromtab

!------------------------------------------------------------------------------!
! Fonction : transtypage v2d -> v3d
!------------------------------------------------------------------------------!
type(v3d) function v3d_fromv2d(v)
implicit none
type(v2d) :: v

  v3d_fromv2d = v3d(v%x, v%y, 0._krp)

endfunction v3d_fromv2d

!------------------------------------------------------------------------------!
! Fonction : transtypage v3d -> real(1:3)
!------------------------------------------------------------------------------!
function tab_v3d(v)
implicit none
type(v3d), intent(in)   :: v
real(krp), dimension(3) :: tab_v3d

  tab_v3d(1:3) = (/ v%x, v%y, v%z /)

endfunction tab_v3d

!------------------------------------------------------------------------------!
! Fonction : transtypage (avec traitement) string -> v3d
!------------------------------------------------------------------------------!
type(v3d) function v3d_fromstr(str, info)
implicit none
character(len=*), intent(in)  :: str
integer,          intent(out) :: info
character(len=len(str))       :: pstr
integer :: id, if

  info = 0
  id   = scan(str, '(')
  if   = scan(str, ')')
  pstr = chg_char(str(id+1:if-1),',',' ') 
  read(pstr,*,iostat=info) v3d_fromstr !%x, v3d_fromstr%z, v3d_fromstr%y
  print*,"TEST V3D",info,":", v3d_fromstr

endfunction v3d_fromstr

!------------------------------------------------------------------------------!
! Fonction : calcul addition de vecteur
!------------------------------------------------------------------------------!
type(v3d) function v3d_addition(v1, v2)
implicit none
type(v3d), intent(in) :: v1, v2

  v3d_addition%x = v1%x + v2%x 
  v3d_addition%y = v1%y + v2%y 
  v3d_addition%z = v1%z + v2%z 

endfunction v3d_addition

!------------------------------------------------------------------------------!
! Fonction : calcul difference de vecteur
!------------------------------------------------------------------------------!
type(v3d) function v3d_substraction(v1, v2)
implicit none
type(v3d), intent(in) :: v1, v2

  v3d_substraction%x = v1%x - v2%x 
  v3d_substraction%y = v1%y - v2%y 
  v3d_substraction%z = v1%z - v2%z 

endfunction v3d_substraction

!------------------------------------------------------------------------------!
! Fonction : calcul de l'oppose d'un vecteur
!------------------------------------------------------------------------------!
type(v3d) function v3d_opp(v)
implicit none
type(v3d), intent(in) :: v

  v3d_opp%x = - v%x 
  v3d_opp%y = - v%y 
  v3d_opp%z = - v%z 

endfunction v3d_opp

!------------------------------------------------------------------------------!
! Fonction : calcul de multiplication de vecteur par reel
!------------------------------------------------------------------------------!
type(v3d) function v3d_multiplysp(x, v)
implicit none
real(4),   intent(in) :: x
type(v3d), intent(in) :: v

  v3d_multiplysp%x = x * v%x 
  v3d_multiplysp%y = x * v%y 
  v3d_multiplysp%z = x * v%z 

endfunction v3d_multiplysp

!------------------------------------------------------------------------------!
! Fonction : calcul de multiplication de vecteur par reel
!------------------------------------------------------------------------------!
type(v3d) function v3d_multiplydp(x, v)
implicit none
real(8),   intent(in) :: x
type(v3d), intent(in) :: v

  v3d_multiplydp%x = x * v%x 
  v3d_multiplydp%y = x * v%y 
  v3d_multiplydp%z = x * v%z 

endfunction v3d_multiplydp

!------------------------------------------------------------------------------!
! Fonction : calcul de division de vecteur par reel
!------------------------------------------------------------------------------!
type(v3d) function v3d_divisionsp(v,x)
implicit none
real(4),   intent(in) :: x
type(v3d), intent(in) :: v

  v3d_divisionsp%x = v%x / x   ! DEV / a optimiser
  v3d_divisionsp%y = v%y / x
  v3d_divisionsp%z = v%z / x 

endfunction v3d_divisionsp

!------------------------------------------------------------------------------!
! Fonction : calcul de division de vecteur par reel
!------------------------------------------------------------------------------!
type(v3d) function v3d_divisiondp(v,x)
implicit none
real(8),   intent(in) :: x
type(v3d), intent(in) :: v

  v3d_divisiondp%x = v%x / x    ! DEV / a optimiser
  v3d_divisiondp%y = v%y / x
  v3d_divisiondp%z = v%z / x 

endfunction v3d_divisiondp

!------------------------------------------------------------------------------!
! Fonction : norme de vecteur
!------------------------------------------------------------------------------!
real(krp) function v3d_norme(v)
implicit none
type(v3d), intent(in) :: v

  v3d_norme = sqrt(v%x*v%x + v%y*v%y + v%z*v%z)

endfunction v3d_norme


!------------------------------------------------------------------------------!
! Fonction : carre de la norme de vecteur
!------------------------------------------------------------------------------!
real(krp) function v3d_sqrnorme(v)
implicit none
type(v3d), intent(in) :: v

  v3d_sqrnorme = v%x*v%x + v%y*v%y + v%z*v%z

endfunction v3d_sqrnorme

!------------------------------------------------------------------------------!
! Fonction : calcul de produit scalaire
!------------------------------------------------------------------------------!
real(krp) function v3d_scalar_product(v1, v2)
implicit none
type(v3d), intent(in) :: v1, v2

  v3d_scalar_product = v1%x*v2%x + v1%y*v2%y + v1%z*v2%z

endfunction v3d_scalar_product

!------------------------------------------------------------------------------!
! Fonction : produit vectoriel
!------------------------------------------------------------------------------!
type(v3d) function v3d_vectorial_product(v1, v2)
implicit none
type(v3d), intent(in) :: v1, v2

  v3d_vectorial_product%x = v1%y*v2%z - v1%z*v2%y
  v3d_vectorial_product%y = v1%z*v2%x - v1%x*v2%z
  v3d_vectorial_product%z = v1%x*v2%y - v1%y*v2%x

endfunction v3d_vectorial_product




endmodule GEO3D

!------------------------------------------------------------------------------!
! Historique des modifications
!
! mai  2002 : creation du module
! juil 2003 : compatibilite des operateurs toute precision
!------------------------------------------------------------------------------!

