!------------------------------------------------------------------------------!
! Procedure : echange            	  Auteur : E. Radenac
!                                         Date   : Mai 2003
! Fonction                                Modif  : Juin 2003
!   Echange de donn�es entre zones de calcul
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine echange(echdata1, echdata2, normale, vecinter, d1, d2, nfacelim, &
			typecalcul, typemethode, condrac1, condrac2, &
                        solvercoupling)

use TYPHMAKE
use OUTPUT
use GEO3D
use DEFFIELD
use VARCOM

implicit none

! -- Declaration des entr�es --
type(st_genericfield)      :: echdata1, echdata2
integer                    :: nfacelim   ! nombre de faces limites sur l'interface
type(v3d), dimension(nfacelim) &
                           :: vecinter                ! vecteur unitaire "intercellules"                       
type(v3d), dimension(nfacelim) &
                           :: normale ! normales � l'interface

real(krp), dimension(nfacelim) &
		           :: d1, d2  ! distance entre les centres des cellules gauche,
		      		      ! droite et l'interface
integer                    :: typecalcul, typemethode
integer                    :: solvercoupling

! -- Declaration des entr�es/sorties --
type(st_genericfield)      :: condrac1, condrac2

! -- Declaration des variables internes --

! -- Debut de la procedure --

select case(solvercoupling)

case(kdif_kdif)
call echange_kdif(echdata1, echdata2, normale, vecinter, d1, d2, nfacelim, &
 			typecalcul, typemethode, condrac1, condrac2)
case(kdif_ns)
call erreur("incoh�rence interne (echange)", "non impl�ment�")

case(ns_ns)
call erreur("incoh�rence interne (echange)", "non impl�ment�")

case default
call erreur("incoh�rence interne (echange)", "couplage de solvers inconnu")

endselect


! "D�termination" du pas de temps d'�change (minimum, maximum, senseurs) avant l'�change suivant
! ??
!call calc_tps_echange()


endsubroutine echange
