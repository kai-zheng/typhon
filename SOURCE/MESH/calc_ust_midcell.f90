!------------------------------------------------------------------------------!
! Procedure : calc_ust_midcell            Auteur : J. Gressier
!                                         Date   : Janvier 2003
! Fonction                                Modif  :
!   calcul approximatif d'un centre de cellule (midcell) pour la definition
!   de volumes elementaires
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine calc_ust_midcell(ncell, facecell, cgface, midcell)

use TYPHMAKE
use OUTPUT
use USTMESH

implicit none

! -- Declaration des entrees --
integer                 :: ncell      ! nombre de cellules
type(st_connect)     :: facecell   ! connectivite face->cellules
type(v3d), dimension(*) :: cgface     ! barycentre de face

! -- Declaration des sorties --
type(v3d), dimension(ncell) :: midcell    ! centre de cellule ( /= barycentre )

! -- Declaration des variables internes --
integer, dimension(:), allocatable &
                        :: nbface       ! nb de faces par cellule
integer                 :: if           ! indice  de face
integer                 :: ic, ic1, ic2 ! indices de cellules

! -- Debut de la procedure --

! Pour chaque cellule, on veut faire la moyenne des barycentres (cgface) de chaque face 
! associee.
! Intuitivement, on aimerait, pour chaque cellule, ajouter la contribution de chacune
! des faces associees.
! Puisque c'est la connectivite face->cellules qui est donnee et non le contraire, on
! boucle sur les faces et ajoute les contributions a chaque cellule.
! (il faut faire attention aux faces limites qui ne sont connectees qu'a une cellule)
! Il faut compter le nombre de faces pour chaque cellules pour calculer le barycentre

! Initialisation

allocate(nbface(ncell))
nbface(:)        = 0
midcell(1:ncell) = v3d(0.,0.,0.)

! boucle sur la liste des faces et sommation pour les cellules

do if = 1, facecell%nbnodes

  ic1 = facecell%fils(if,1)
  ic2 = facecell%fils(if,2)

  ! premiere cellule connectee
  midcell(ic1) = midcell(ic1) + cgface(if)
  nbface (ic1) = nbface (ic1) + 1

  ! seconde cellule connectee (si existante)
  if (ic2 /= 0) then
    midcell(ic2) = midcell(ic2) + cgface(if)
    nbface (ic2) = nbface (ic2) + 1
  endif

enddo

! calcul de la moyenne sur les cellules

do ic = 1, ncell
  midcell(ic) = midcell(ic) / real(nbface(ic),kind=krp)
enddo

deallocate(nbface)

endsubroutine calc_ust_midcell
