!------------------------------------------------------------------------------!
! MODULE : DEFZONE                        Auteur : J. Gressier
!                                         Date   : Juillet 2002
! Fonction                                Modif  : (cf historique)
!   Definition des structures de donnees des zones (contient
!   maillage, type de solveur et info)
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!

module DEFZONE

use TYPHMAKE      ! Definition de la precision/donnees informatiques
use MODINFO       ! Information pour la gestion de l'integration
use MENU_SOLVER   ! Definition des solveurs
use MENU_NUM      ! Definition des parametres numeriques d'integration
use MENU_MESH     ! Definition du maillage
use MGRID         ! Definition des grilles
use STRMESH       ! Definition des maillages structures
use USTMESH       ! Definition des maillages non structures
!use BOUND        ! Librairie de definition des conditions aux limites
use MENU_ZONECOUPLING ! Definition des structures d'echange entre zones
use DEFFIELD      ! Donnees des champs physiques
use DEFCAPTEURS   ! Donnees des capteurs 

implicit none

! -- Variables globales du module -------------------------------------------



! -- DECLARATIONS -----------------------------------------------------------

!------------------------------------------------------------------------------!
! Definition de la structure ST_ZONE : zone maillage general et champ
!------------------------------------------------------------------------------!
type st_zone
  integer               :: id         ! numero de zone
  character(len=strlen) :: nom        ! nom de la zone
  !integer               :: ndom       ! nombre de domaine total (cas hybride)
  !integer               :: nmesh_str  ! nombre de domaines     structures
  !integer               :: nmesh_ust  ! nombre de domaines non structures
  integer               :: nprobe     ! nombre de capteurs
  integer               :: ncoupling  ! nombre d'echanges avec d'autres zones
  type(st_infozone)     :: info       ! information sur l'integration
  type(mnu_solver)      :: defsolver  ! type de solveur a utiliser 
  type(mnu_time)        :: deftime    ! parametres d'integration temporelle
  type(mnu_spat)        :: defspat    ! parametres d'integration spatiale
                                      !   cf definitions variables globales
  type(mnu_mesh)        :: defmesh    ! type de maillage
  character             :: typ_mesh   ! type de maillage (cf VARCOM)
                                      !   S : multibloc structure
                                      !   U : non structure
                                      !   H : hybride
  integer               :: mpi_cpu    ! numero de CPU charge du calcul

  !type(st_strmesh), dimension(:), pointer &
  !                      :: str_mesh   ! maillage multibloc structure
  integer                :: ngrid      ! nombre de grilles (mesh + field)
  type(st_grid), pointer :: grid       ! liste chainee de grilles
  !integer               :: nmesh      ! nombre champs (liste chainee)  
  !integer               :: nfield     ! nombre champs (liste chainee)  
  !type(st_ustmesh), pointer &
  !type(st_ustmesh) & !, dimension(:), pointer &
  !                      :: ust_mesh   ! liste chainee de maillage non structure
  !type(st_field), pointer &
  !type(st_field), dimension(:), pointer &
  !                      :: field      ! tableau des champs
  type(st_capteur), dimension(:), pointer &
                        :: probe      ! tableau des capteurs
  type(mnu_zonecoupling), dimension(:), pointer &
                        :: coupling   !definition des raccords avec d'autres zones
endtype st_zone


! -- INTERFACES -------------------------------------------------------------

interface new
  module procedure new_zone
endinterface

interface delete
  module procedure delete_zone
endinterface

! -- Fonctions et Operateurs ------------------------------------------------


! -- IMPLEMENTATION ---------------------------------------------------------
contains


!------------------------------------------------------------------------------!
! Procedure : initialisation d'une structure ZONE
!------------------------------------------------------------------------------!
subroutine new_zone(zone, id)
implicit none
type(st_zone)  :: zone
integer        :: id

  zone%id = id

  !zone%ndom  = 0   ! DEV: a supprimer apres homogeneisation dans MGRID

  zone%ngrid = 0
  nullify(zone%grid)

endsubroutine new_zone


!------------------------------------------------------------------------------!
! Procedure : desallocation d'une structure ZONE
!------------------------------------------------------------------------------!
subroutine delete_zone(zone)
implicit none
type(st_zone)  :: zone
integer        :: i     

  !print*,'DEBUG: destruction de zone '
  !if (zone%nmesh_str >= 1) then
  !  do i = 1, zone%nmesh_str
  !    call delete(zone%str_mesh(i))   
  !  enddo 
  !  deallocate(zone%str_mesh)
  !endif
  
  call delete(zone%defsolver)
  
  ! Destruction des structures USTMESH (DEV: dans MGRID)
  !if (zone%nmesh_ust >= 1) then
  !  print*,"desallocation ust_mesh" !! DEBUG
  !  call delete(zone%ust_mesh)
  !endif
  
!  if (zone%ncoupling >= 1) then
    print*,"desallocation tableau coupling" !! DEBUG
    do i = 1, zone%ncoupling
      print*,"desallocation coupling ",i !! DEBUG
      call delete(zone%coupling(i))
    enddo  
    deallocate(zone%coupling)
!  endif

  ! Destruction des champs (structures FIELD) (DEV: dans MGRID)
  !print*,'debug delete_zone : ',zone%ndom,' ndom'
  !do i = 1, zone%ndom
  !  print*,"desallocation champ ",i !! DEBUG
  !  call delete(zone%field(i))
  !enddo
  !if (zone%ndom >= 1) deallocate(zone%field)

  ! Destruction des structures MGRID

  print*,'DEV!!! destruction des MGRID a effectuer'  

  !print*,'fin de destruction de zone interne' !! DEBUG

endsubroutine delete_zone


!------------------------------------------------------------------------------!
! Procedure : ajout avec allocation d'une structure grille (par insertion)
!------------------------------------------------------------------------------!
function newgrid(zone) result(pgrid)
implicit none
type(st_grid), pointer :: pgrid
type(st_zone)          :: zone
integer                :: id

  zone%ngrid = zone%ngrid + 1

  if (zone%ngrid == 1) then
   allocate(pgrid)
   call new(pgrid, zone%ngrid)
  else
    pgrid => insert_newgrid(zone%grid, zone%ngrid)
  endif

  pgrid%nbocofield = 0
  pgrid%nfield = 0

  zone%grid => pgrid

endfunction newgrid



endmodule DEFZONE

!------------------------------------------------------------------------------!
! Historique des modifications
!
! juil 2002 : creation du module
! juin 2003 : structuration des champs par type (scalaire, vecteur...)
! juil 2003 : delete zone%defsolver
! mars 2003 : structure "grid" (mesh + field) en liste chainee
!------------------------------------------------------------------------------!
