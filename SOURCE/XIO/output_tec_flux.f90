!------------------------------------------------------------------------------!
! Procedure : output_tec_flux             Auteur : E. Radenac / J. Gressier
!                                         Date   : Fevrier 2004
! Fonction                                Modif  : (cf Historique)
!   Affichage au format tecplot des flux a l'interface
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine output_tec_flux(nom, lworld, io)
 
use TYPHMAKE
use OUTPUT
use VARCOM
use MODWORLD

implicit none

! -- Declaration des entrees --
character(len=strlen) :: nom       ! nom du fichier
type(st_world)        :: lworld
integer               :: io        ! indice de la sortie

! -- Declaration des sorties --

! -- Declaration des variables internes --
integer   :: izone, ir
integer   :: iz1, iz2, ncoupl1, ncoupl2,  nbc1, nbc2

! -- Debut de la procedure --
if (lworld%info%curtps == 0) then
  open(unit = uf_compflux, file = trim(lworld%output(io)%fichier), form = 'formatted')
  write(uf_compflux, '(a)') 'VARIABLES="t","F1","F2", "ERREUR", "Fcalcule", "ERRCALC"'
endif

! Calcul des conditions aux limites pour le calcul des flux a l'interface

do izone = 1, lworld%prj%nzone
 call conditions_limites(lworld%zone(izone))
enddo

if (lworld%prj%ncoupling > 0) then

ir =1 ! DVT : provisoire
    
! calcul des donnees de raccord : indices de raccord, de CL pour les 
! deux zones couplees
call calcul_raccord(lworld, ir, iz1, iz2, ncoupl1, ncoupl2, nbc1, nbc2)

call comp_flux(lworld%zone(iz1), lworld%zone(iz2), nbc1, nbc2, &
               lworld%zone(iz1)%gridlist%first%umesh%boco(nbc1)%nface, lworld%info%curtps,&
               ncoupl1)
endif

endsubroutine output_tec_flux

!------------------------------------------------------------------------------!
! Historique des modifications
!
! fev 2004   : creation de la procedure
!------------------------------------------------------------------------------!
