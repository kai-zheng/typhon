!------------------------------------------------------------------------------!
! MODULE : CONNECTIVITY                   Auteur : J. Gressier
!                                         Date   : Juillet 2003
! Fonction                                Modif  : (cf historique)
!   Bibliotheque de procedures et fonctions pour la gestion de connectivités
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!

module CONNECTIVITY

use TYPHMAKE   ! Definition de la precision

implicit none

! -- Variables globales du module -------------------------------------------


! -- DECLARATIONS -----------------------------------------------------------


!------------------------------------------------------------------------------!
! structure ST_ELEMC : Définition d'un élément de connectivité 
!------------------------------------------------------------------------------!
type st_elemc
  integer                 :: nbfils      ! nombre de connectivités
  integer, dimension(:), pointer &
                          :: fils        ! définition de la connectivité
endtype st_elemc


!------------------------------------------------------------------------------!
! structure ST_CONNECT : Définition de connectivité à nombre de fils constants
!------------------------------------------------------------------------------!
type st_connect
  integer                 :: nbnodes     ! nombre de d'ensemble connectivités
  integer                 :: nbfils      ! nombre de connectivités par ensemble
  integer, dimension(:,:), pointer &
                          :: fils        ! définition de la connectivité
endtype st_connect


!------------------------------------------------------------------------------!
! structure ST_GENCONNECT : Définition de connectivité à nombre de fils variables
!------------------------------------------------------------------------------!
type st_genconnect
  integer                 :: nbnodes     ! nombre de d'ensemble connectivités
  type(st_elemc), dimension(:), pointer &
                          :: noeud       ! nombre de fils pour chaque noeud
endtype st_genconnect




! -- INTERFACES -------------------------------------------------------------

interface new
  module procedure new_connect, new_genconnect, new_genconnect2
endinterface

interface delete
  module procedure delete_connect, delete_genconnect
endinterface

interface copy
  module procedure copy_connect
endinterface

interface realloc
  module procedure realloc_connect
endinterface



! -- Fonctions et Operateurs ------------------------------------------------



! -- IMPLEMENTATION ---------------------------------------------------------
contains


!------------------------------------------------------------------------------!
! Procédure : allocation d'une structure CONNECT
!------------------------------------------------------------------------------!
subroutine new_connect(conn, nbnodes, nbfils)
implicit none
type(st_connect) :: conn
integer             :: nbnodes, nbfils

  conn%nbnodes = nbnodes
  conn%nbfils  = nbfils
  allocate(conn%fils(nbnodes, nbfils))

endsubroutine new_connect


!------------------------------------------------------------------------------!
! Procédure : reallocation d'une structure CONNECT
!------------------------------------------------------------------------------!
subroutine realloc_connect(conn, nbnodes, nbfils)
implicit none
type(st_connect) :: conn, prov
integer             :: nbnodes,      nbfils      ! nouvelle taille
integer             :: old_nbnodes, old_nbfils   ! ancienne taille
integer             :: min_nbnodes, min_nbfils   ! ancienne taille

  prov = copy(conn)
  conn%nbnodes = nbnodes                   ! affectation des nouvelles tailles
  conn%nbfils  = nbfils 
  deallocate(conn%fils)                    ! désallocation de l'ancien tableau     
  allocate(conn%fils(nbnodes, nbfils))     ! allocation du nouveau tableau
  conn%fils(1:nbnodes, 1:nbfils) = 0       ! initialisation
  min_nbnodes = min(nbnodes, prov%nbnodes)
  min_nbfils  = min(nbfils,  prov%nbfils)  ! copie des connectivités
  conn%fils(1:min_nbnodes, 1:min_nbfils) = prov%fils(1:min_nbnodes, 1:min_nbfils) 

endsubroutine realloc_connect


!------------------------------------------------------------------------------!
! Procédure : allocation d'une structure CONNECT par copie
!------------------------------------------------------------------------------!
function copy_connect(source)
implicit none
type(st_connect) :: copy_connect, source

  copy_connect%nbnodes = source%nbnodes
  copy_connect%nbfils  = source%nbfils
  allocate(copy_connect%fils(copy_connect%nbnodes, copy_connect%nbfils))
  copy_connect%fils    = source%fils

endfunction copy_connect


!------------------------------------------------------------------------------!
! Procédure : desallocation d'une structure CONNECT
!------------------------------------------------------------------------------!
subroutine delete_connect(conn)
implicit none
type(st_connect) :: conn

  conn%nbnodes = 0
  if (associated(conn%fils)) deallocate(conn%fils)

endsubroutine delete_connect


!------------------------------------------------------------------------------!
! Procédure : allocation d'une structure GENCONNECT sans nombre de fils
!------------------------------------------------------------------------------!
subroutine new_genconnect(conn, nbnodes)
  implicit none
  type(st_genconnect) :: conn
  integer             :: nbnodes
  integer             :: i

  conn%nbnodes = nbnodes
  allocate(conn%noeud(nbnodes))
  do i = 1, nbnodes
    conn%noeud(i)%nbfils = 0
  enddo

endsubroutine new_genconnect


!------------------------------------------------------------------------------!
! Procédure : allocation d'une structure GENCONNECT avec nombre de fils
!------------------------------------------------------------------------------!
subroutine new_genconnect2(conn, nbnodes, nbfils)
  implicit none
  type(st_genconnect) :: conn
  integer             :: nbnodes, nbfils(nbnodes)
  integer             :: i

  conn%nbnodes = nbnodes
  allocate(conn%noeud(nbnodes))
  do i = 1, nbnodes
    conn%noeud(i)%nbfils = nbfils(i)
    allocate(conn%noeud(i)%fils(nbfils(i)))
  enddo

endsubroutine new_genconnect


!------------------------------------------------------------------------------!
! Procédure : desallocation d'une structure GENCONNECT
!------------------------------------------------------------------------------!
subroutine delete_genconnect(conn)
  implicit none
  type(st_genconnect) :: conn
  integer             :: nbnodes
  integer             :: i

  do i = 1, nbnodes
    if (conn%noeud(i)%nbfils /= 0) deallocate(conn%noeud(i)%fils)
  enddo
  deallocate(conn%noeud(nbnodes))
  conn%nbnodes = 0

endsubroutine delete_genconnect







endmodule CONNECTIVITY

!------------------------------------------------------------------------------!
! Historique des modifications
!
! juil 2003 : création du module, connectivité simple et généralisée
!------------------------------------------------------------------------------!



