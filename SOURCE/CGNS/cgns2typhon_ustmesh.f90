!------------------------------------------------------------------------------!
! Procedure : cgns2typhon_ustmesh         Auteur : J. Gressier
!                                         Date   : Novembre 2002
! Fonction                                Modif  : (cf historique)
!   Conversion d'une zone CGNS en structure Maillage NON structuré pour Typhon
!   Création des connectivités FACE->SOMMETS et FACES->CELLULES
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!

subroutine cgns2typhon_ustmesh(cgnszone, mesh) 

use CGNS_STRUCT   ! Définition des structures CGNS
use DEFZONE       ! Définition des structures ZONE
use USTMESH       ! Définition des structures maillages non structurés
use OUTPUT        ! Sorties standard TYPHON

implicit none 

! -- Entrées --
type(st_cgns_zone) :: cgnszone          ! structure ZONE des données CGNS

! -- Sorties --
type(st_ustmesh)   :: mesh           ! structure USTMESH des données TYPHON

! -- Variables internes --
integer, parameter  :: nmax_cell = 20   ! nb max de cellules dans la connectivité vtex->cell
type(st_connect)    :: face_vtex, &     ! connectivité intermédiaire faces   -> sommets
                       face_cell        ! connectivité intermédiaire faces   -> cellules
integer             :: ntotcell         ! calcul du nombre total de cellules
integer             :: maxvtex, maxface ! nombre de sommets/face, face/cellule
integer             :: nface            ! estimation du nombre de faces
integer             :: iconn, icell, ivtex   ! indices courants

! -- Début de procédure

call print_info(8,". conversion du maillage et création des connectivités")

if (cgnszone%type /= Unstructured) then
  call erreur("Développement","incohérence dans l'appel de subroutine")
endif

select case(cgnszone%imesh)    ! transfert du nombre de dimensions (2D ou 3D)
case(2)
  mesh%mesh%info%geom = msh_2dplan
case(3)
  mesh%mesh%info%geom = msh_3d
endselect

! --- conversion du nuage du point ---

call print_info(8,"  nuage de points")

mesh%mesh%nvtex  = cgnszone%mesh%ni         ! nb de sommets
allocate(mesh%mesh%vertex(mesh%mesh%nvtex, 1, 1))
mesh%mesh%vertex = cgnszone%mesh%vertex     ! copie du nuage de points
mesh%nvtex       = mesh%mesh%nvtex          ! nb de sommets (redondant)

! on spécifie que le tableau de faces ne sera pas allouée
nullify(mesh%mesh%iface)
mesh%mesh%nface = 0

! --- création des connectivités (cellule -> faces) et (face -> sommets) ---

call print_info(8,"  création des faces et connectivités associées")

! recherche des tailles de tableaux selon les types d'éléments

ntotcell = 0    ! nombre total de cellules
maxvtex  = 0    ! nombre de sommets max par face
maxface  = 0    ! nombre de faces   max par cellule
nface    = 0    ! estimation du nombre de faces max

call init(mesh%cellvtex)

do iconn = 1, cgnszone%ncellfam          ! boucle sur les sections de cellules
 
  ! cumul du nombre de cellules
  ntotcell = ntotcell + cgnszone%cellfam(iconn)%nbnodes  
  !print*,iconn," ",cgnszone%cellfam(iconn)%type !! DEBUG
  select case(cgnszone%cellfam(iconn)%type)
  case(NODE)
    call erreur("Développement", "Type de cellule inattendu (NODE)")
  case(BAR_2,BAR_3)
    call erreur("Développement", "Type de cellule inattendu (BAR)")
  case(TRI_3,TRI_6)
    maxvtex = max(maxvtex, 2)
    maxface = max(maxface, 3)
    nface   = nface + 3*cgnszone%cellfam(iconn)%nbnodes
    mesh%cellvtex%ntri = mesh%cellvtex%ntri + cgnszone%cellfam(iconn)%nbnodes
  case(QUAD_4,QUAD_8,QUAD_9)
    maxvtex = max(maxvtex, 2)
    maxface = max(maxface, 4)
    nface   = nface + 4*cgnszone%cellfam(iconn)%nbnodes
    mesh%cellvtex%nquad = mesh%cellvtex%nquad + cgnszone%cellfam(iconn)%nbnodes
  case(TETRA_4,TETRA_10)
    maxvtex = max(maxvtex, 3)
    maxface = max(maxface, 4)
    nface   = nface + 4*cgnszone%cellfam(iconn)%nbnodes
    mesh%cellvtex%ntetra = mesh%cellvtex%ntetra + cgnszone%cellfam(iconn)%nbnodes
  case(PYRA_5,PYRA_14)
    maxvtex = max(maxvtex, 4)
    maxface = max(maxface, 5)
    nface   = nface + 5*cgnszone%cellfam(iconn)%nbnodes
    mesh%cellvtex%npyra = mesh%cellvtex%npyra + cgnszone%cellfam(iconn)%nbnodes
  case(PENTA_6,PENTA_15,PENTA_18)
    maxvtex = max(maxvtex, 4)
    maxface = max(maxface, 5)
    nface   = nface + 5*cgnszone%cellfam(iconn)%nbnodes
    mesh%cellvtex%npenta = mesh%cellvtex%npenta + cgnszone%cellfam(iconn)%nbnodes
  case(HEXA_8,HEXA_20,HEXA_27)
    maxvtex = max(maxvtex, 4)
    maxface = max(maxface, 6)
    nface   = nface + 6*cgnszone%cellfam(iconn)%nbnodes
    mesh%cellvtex%nhexa = mesh%cellvtex%nhexa + cgnszone%cellfam(iconn)%nbnodes
  case(MIXED, NGON_n)
    call erreur("Gestion CGNS", "Eléments MIXED et NFON_n non traités")
  case default
    call erreur("Gestion CGNS", "Type d'élément non reconnu dans CGNSLIB")
  endselect
enddo

! -- copie des connectivités cell->vtex --

call new(mesh%cellvtex)

do iconn = 1, cgnszone%ncellfam          ! boucle sur les sections de cellules
 
  select case(cgnszone%cellfam(iconn)%type)
  case(NODE)
    call erreur("Développement", "Type de cellule inattendu (NODE)")
  case(BAR_2,BAR_3)
    call erreur("Développement", "Type de cellule inattendu (BAR)")
  case(TRI_3)
    mesh%cellvtex%tri%fils(:,1:3) = cgnszone%cellfam(iconn)%fils(:,1:3)
    mesh%cellvtex%itri(:) = (/ (icell, icell = cgnszone%cellfam(iconn)%ideb, &
                                               cgnszone%cellfam(iconn)%ifin  ) /)
  case(TRI_6)
    call erreur("Développement", "Type de cellule inattendu (TRI_6)")
    !mesh%cellvtex%tri%fils(:,1:3) = cgnszone%cellfam(iconn)%fils(:,1:3)
  case(QUAD_4)
    mesh%cellvtex%quad%fils(:,1:4) = cgnszone%cellfam(iconn)%fils(:,1:4)
    mesh%cellvtex%iquad(:) = (/ (icell, icell = cgnszone%cellfam(iconn)%ideb, &
                                                cgnszone%cellfam(iconn)%ifin  ) /)
  case(QUAD_8,QUAD_9)
    call erreur("Développement", "Type de cellule inattendu (QUAD_8/9)")
  case(TETRA_4)
    mesh%cellvtex%tetra%fils(:,1:4) = cgnszone%cellfam(iconn)%fils(:,1:4)
    mesh%cellvtex%itetra(:) = (/ (icell, icell = cgnszone%cellfam(iconn)%ideb, &
                                                 cgnszone%cellfam(iconn)%ifin  ) /)
  case(TETRA_10)
    call erreur("Développement", "Type de cellule inattendu (TETRA_10)")
  case(PYRA_5)
    mesh%cellvtex%pyra%fils(:,1:5) = cgnszone%cellfam(iconn)%fils(:,1:5)
    mesh%cellvtex%ipyra(:) = (/ (icell, icell = cgnszone%cellfam(iconn)%ideb, &
                                                cgnszone%cellfam(iconn)%ifin  ) /)
  case(PYRA_14)
    call erreur("Développement", "Type de cellule inattendu (PYRA_14)")
  case(PENTA_6)
    mesh%cellvtex%penta%fils(:,1:6) = cgnszone%cellfam(iconn)%fils(:,1:6)
    mesh%cellvtex%ipenta(:) = (/ (icell, icell = cgnszone%cellfam(iconn)%ideb, &
                                                 cgnszone%cellfam(iconn)%ifin  ) /)
  case(PENTA_15,PENTA_18)
    call erreur("Développement", "Type de cellule inattendu (PENTA_15/18)")
  case(HEXA_8)
    mesh%cellvtex%hexa%fils(:,1:8) = cgnszone%cellfam(iconn)%fils(:,1:8)
    mesh%cellvtex%ihexa(:) = (/ (icell, icell = cgnszone%cellfam(iconn)%ideb, &
                                                cgnszone%cellfam(iconn)%ifin  ) /)
  case(HEXA_20,HEXA_27)
    call erreur("Développement", "Type de cellule inattendu (HEXA_20/27)")
  case(MIXED, NGON_n)
    call erreur("Gestion CGNS", "Eléments MIXED et NFON_n non traités")
  case default
    call erreur("Gestion CGNS", "Type d'élément non reconnu dans CGNSLIB")
  endselect
enddo

! allocation des tableaux de connectivités

! -- connectivité intermédiaire face->sommets --
call new(face_vtex, nface, maxvtex)
face_vtex%nbnodes   = 0                     ! réinitialisation : nombre de faces crées
face_vtex%fils(:,:) = 0                     ! initialisation de la connectivité

! -- connectivité intermédiaire face->cellules --
call new(face_cell, nface, 2)
face_cell%nbnodes   = 0                     ! réinitialisation : nombre de faces crées
face_cell%fils(:,:) = 0                     ! initialisation de la connectivité

! -- création des faces et des connectivités --

do iconn = 1, cgnszone%ncellfam          ! boucle sur les sections de cellules
  call createface_fromcgns(mesh%nvtex, cgnszone%cellfam(iconn), &
                           face_cell, face_vtex)
enddo

! Recopie des connectivités dans la structure TYPHON
! avec le nombre exact de faces reconstruites

nface          = face_vtex%nbnodes     ! meme valeur que face_cell%nbnodes aussi
mesh%nface     = nface
mesh%ncell_int = ntotcell
write(str_w,'(i10,a)') nface,"faces créées"
call print_info(8,str_w)

call new(mesh%facevtex, nface, maxvtex)
call new(mesh%facecell, nface, 2)

mesh%facevtex%fils(1:nface,1:maxvtex) = face_vtex%fils(1:nface,1:maxvtex)
mesh%facecell%fils(1:nface,1:2)       = face_cell%fils(1:nface,1:2)

! désallocation
!deallocate(vtex_cell, ncell)
call delete(face_cell)
call delete(face_vtex)

! -- Renumérotation des faces --

call reorder_ustconnect(0, mesh)    ! action sur les connectivités uniquement

! -- Conversion des conditions aux limites  --

call cgns2typhon_ustboco(cgnszone, mesh)

!print*,"fin de création des structures TYPHON" !!! DEBUG

mesh%ncell_lim = mesh%nface_lim
mesh%ncell     = mesh%ncell_int + mesh%ncell_lim

!-------------------------
endsubroutine cgns2typhon_ustmesh

!------------------------------------------------------------------------------!
! Historique des modifications
!
! nov  2002 : création de la procédure
! fev  2004 : renseignements dans structure INFO_MESH
! juin 2004 : mémorisation de la connectivité cell->vtex
!------------------------------------------------------------------------------!



