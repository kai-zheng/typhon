!------------------------------------------------------------------------------!
! Procedure : def_mesh                    Auteur : J. Gressier
!                                         Date   : Novembre 2002
! Fonction                                Modif  : (cf historique)
!   Traitement des param�tres du fichier menu principal
!   D�finition du maillage
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine def_mesh(block, defmesh)

use RPM
use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_MESH

implicit none

! -- Declaration des entr�es --
type(rpmblock), target :: block

! -- Declaration des sorties --
type(mnu_mesh) :: defmesh

! -- Declaration des variables internes --
type(rpmblock), pointer  :: pblock, pcour  ! pointeur de bloc RPM
integer                  :: nkey           ! nombre de clefs
integer                  :: i
character(len=dimrpmlig) :: str            ! cha�ne RPM interm�diaire

! -- Debut de la procedure --

call print_info(5,"- D�finition du maillage")

! -- Recherche du BLOCK:MESH

pblock => block
call seekrpmblock(pblock, "MESH", 0, pcour, nkey)

if (nkey /= 1) call erreur("lecture de menu", &
                           "bloc MESH inexistant ou surnum�raire")

! -- lecture du format

call rpmgetkeyvalstr(pcour, "FORMAT", str)
defmesh%format = cnull

if (samestring(str,"CGNS"))    defmesh%format = fmt_CGNS
if (samestring(str,"TYPHMSH")) defmesh%format = fmt_TYPHMSH
if (defmesh%format == cnull) call erreur("lecture de menu","format de maillage inconnu")

! -- lecture du nom de fichier

call rpmgetkeyvalstr(pcour, "FILE", str)
defmesh%fichier = str


endsubroutine def_mesh

!------------------------------------------------------------------------------!
! Historique des modifications
!
! nov  2002 : cr�ation de la proc�dure
! fev  2004 : lecture de format TYPHMSH (format interne)
!------------------------------------------------------------------------------!
