!------------------------------------------------------------------------------!
! Procedure : donnees_echange             Auteur : E. Radenac
!                                         Date   : Juin 2003
! Fonction                                Modif  :
!   Ecrire les donnees variables dans le temps dans une structure 
!   donnees_echange_inst
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!

subroutine donnees_echange(solvercoupling, donnees_echange_inst, zone, &
                           nbc)

use TYPHMAKE
use OUTPUT
use GEO3D
use DEFZONE
use DEFFIELD
use VARCOM

implicit none

! -- Declaration des entr�es --
integer                 :: solvercoupling
type(st_zone)           :: zone
integer                 :: nbc ! num�ro (identit�) de la CL

! -- Declaration donnees_echange    
type(st_genericfield) :: donnees_echange_inst

! -- Declaration des variables internes --

! -- Debut de la procedure --

select case(solvercoupling)
  
  case(kdif_kdif)
  call ech_data_kdif(donnees_echange_inst, zone, nbc)
  
  case(kdif_ns)
  call ech_data_kdif(donnees_echange_inst, zone, nbc)

  case(ns_ns)
  call erreur("incoh�rence interne (donnees_echange)", "cas non impl�ment�")

  case default
  call erreur("incoh�rence interne (donnees_echange)", &
              "couplage de solvers inconnu")

endselect

endsubroutine donnees_echange
