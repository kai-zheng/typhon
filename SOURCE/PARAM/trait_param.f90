!------------------------------------------------------------------------------!
! Procedure : trait_param                             Authors : J. Gressier
!                                                     Created : July 2002
! Fonction                                            Modif   : (cf history)
!   Parse main file parameters / 
!
!------------------------------------------------------------------------------!
subroutine trait_param(block, world)

use RPM
use TYPHMAKE
use VARCOM
use OUTPUT
use MODWORLD
use MENU_SOLVER
use IO_UNIT

implicit none

! -- INPUTS --
type(rpmblock), target :: block

! -- OUTPUTS --
type(st_world) :: world

! -- Private Data --
type(rpmblock), pointer  :: pblock, pcour, pzone  ! pointeurs de bloc RPM
integer                  :: nkey           ! nombre de clefs
logical                  :: localzone      ! declaration locale d'une zone
integer                  :: izone          ! numero local de zone
integer                  :: icoupl         ! numero local de raccord
integer                  :: solver         ! type de solveur
integer                  :: info           ! etat de l'ouverture de fichier
character(len=dimrpmlig) :: str, fic       ! chaines RPM intermediaire
integer                  :: uf_menu

! -- BODY --

! -- Recherche du BLOCK:PROJECT et traitement

call def_project(block, world%prj)

! -- Recherche des BLOCK:ZONE 

pblock => block
call seekrpmblock(pblock, "ZONE", 0, pcour, nkey)
if (nkey == 0) call erreur("Lecture de menu","definition de ZONE manquante")

! initialisation de WORLD et allocation des zones

call new(world, nkey, 0,  world%prj%ncoupling)  

! -- Recherche du BLOCK:OUTPUT et traitement

call def_output(block, world)

! -- Lecture des zones

do izone = 1, world%prj%nzone

  call seekrpmblock(pblock, "ZONE", izone, pcour, nkey)
  
  call new(world%zone(izone), izone)   ! intialisation de la zone

  call rpmgetkeyvalstr(pcour, "NAME", str, "NONAME")
  world%zone(izone)%name = str

  call rpmgetkeyvalstr(pcour, "SOLVER", str)

  solver = 0
  if (samestring(str, "HEAT" ))  solver = solKDIF 
  if (samestring(str, "EULER"))  solver = solNS
  if (samestring(str, "FLUID"))  solver = solNS
  if (samestring(str, "NS"))     solver = solNS
  if (samestring(str, "VORTEX")) solver = solVORTEX
  if (solver == 0) call erreur("Lecture du menu", &
                               "Type de solveur incorrect : "//trim(str))
  
  if (rpm_existkey(pcour, "FILE")) then

    call rpmgetkeyvalstr(pcour, "FILE", fic)
    uf_menu = getnew_io_unit()
    open(unit=uf_menu, file=trim(fic), iostat=info)
    if (info /= 0) call erreur("Lecture du menu","fichier "//trim(fic)// &
                               " introuvable ou interdit en lecture")
    call readrpmblock(uf_menu, uf_log, 1, pzone)
    call close_io_unit(uf_menu) 

  else

    call print_info(10,"Poursuite de la lecture des parametres ZONE")
    pzone => pblock
    
  endif

  call trait_zoneparam(world%prj, pzone, solver, world%zone(izone))

enddo

! -- Recherche des BLOCK:COUPLING et traitement
if (world%prj%ncoupling > 0) then

do icoupl = 1, world%prj%ncoupling

!  print*,"!!! TRAITEMENT DES BLOCK:COUPLING a developper"
  call def_coupling(block, world%coupling(icoupl), world%zone,&
                   world%prj%nzone, icoupl)

enddo

endif

endsubroutine trait_param

!------------------------------------------------------------------------------!
! Historique des modifications
!
! Juil 2002 : creation de la procedure
! Juin 2003 : definition des couplages
! Fev  2004 : ajout de solveur VORTEX
!------------------------------------------------------------------------------!
