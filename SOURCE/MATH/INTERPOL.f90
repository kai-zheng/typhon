!------------------------------------------------------------------------------!
! MODULE : INTERPOL                       Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  : (cf historique)
!   Bibliotheque de procedures pour l'interpolation de donnees
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
module INTERPOL

implicit none

! -- Variables globales du module -------------------------------------------


!------------------------------------------------------------------------------!
!    DECLARATIONS
!------------------------------------------------------------------------------!


! -- INTERFACES -------------------------------------------------------------

interface interlin
  module procedure interlinsp, interlindp
endinterface

interface interpoltab
  module procedure interpoltabsp, interpoltabdp
endinterface

interface getfromtab
  module procedure getfromtabsp, getfromtabdp, getfromtabtsp, getfromtabtdp
endinterface

! -- Procedures, Fonctions et Operateurs ------------------------------------
!
! subroutine rpmerr(message)

!------------------------------------------------------------------------------!
!    IMPLEMENTATION 
!------------------------------------------------------------------------------!
contains

!------------------------------------------------------------------------------!
! Procedure : interpolerr                 Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  :
!   Gestion des erreurs de la librairie INTERPOL
!
!------------------------------------------------------------------------------!
subroutine interpolerr(message)
  implicit none 
! -- Declaration des Parametres --
  character(len=*) :: message
! -- Debut de la procedure --
  print*,'** librairie INTERPOL - erreur : ' // message // ' **'
  stop
endsubroutine interpolerr
!------------------------------------------------------------------------------!
  

!------------------------------------------------------------------------------!
! Fonction : interlinsp/dp                Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  :
!   Interpolation (ou extrapolation) d'une valeur ymid a partir de
!   deux couples de valeurs (x,y) et d'une donnee xmid
!
! Defauts/Limitations/Divers :
!   L'interpolation est lineaire, en simple precision
!
!------------------------------------------------------------------------------!
function interlinsp(x, cp1, cp2)

implicit none 

! -- Declaration des entrees --
real               :: x           ! point pour l'interpolation
real, dimension(2) :: cp1, cp2    ! donnees pour la definition de la droite

! -- Declaration des sorties --
real               :: interlinsp

! -- Declaration des variables internes --

! -- Debut de la procedure --
  if (cp1(1) == cp2(1)) then
    call interpolerr("Donnees degenerees pour l'interpolation")
  else
    interlinsp = cp1(2) + (x-cp1(1)) * (cp2(2)-cp1(2)) / (cp2(1)-cp1(1))
  endif
  
endfunction interlinsp
!------------------------------------------------------------------------------!

function interlindp(x, cp1, cp2)

implicit none 

! -- Declaration des entrees --
double precision               :: x         ! point pour l'interpolation
double precision, dimension(2) :: cp1, cp2  ! donnees pour la def. de la droite

! -- Declaration des sorties --
double precision               :: interlindp

! -- Declaration des variables internes --

! -- Debut de la procedure --
  if (cp1(1) == cp2(1)) then
    call interpolerr("Donnees degenerees pour l'interpolation lineaire")
  else
    interlindp = cp1(2) + (x-cp1(1)) * (cp2(2)-cp1(2)) / (cp2(1)-cp1(1))
  endif
  
endfunction interlindp
!------------------------------------------------------------------------------!


!------------------------------------------------------------------------------!
! Fonction : interparab                   Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  :
!   Interpolation (ou extrapolation) d'une valeur ymid a partir de
!   trois couples de valeurs (x,y) et d'une donnee xmid
!
! Defauts/Limitations/Divers :
!   L'interpolation est parabolique
!
!------------------------------------------------------------------------------!
function interparab(x, cp1, cp2, cp3)

implicit none 

! -- Declaration des entrees --
real               :: x             ! point pour l'interpolation
real, dimension(2) :: cp1, cp2, cp3 ! donnees pour la definition de la parabole

! -- Declaration des sorties --
real               :: interparab

! -- Declaration des variables internes --
real d12, d13, d23, det, a, b, c, dy1, dy2, dy3

! -- Debut de la procedure --
  d12 = cp2(1) - cp1(1)
  d13 = cp3(1) - cp1(1)
  d23 = cp3(1) - cp2(1)
  det = -d12*d13*d23
  if (det == 0) then
    call interpolerr("Donnees degenerees pour l'interpolation parabolique")
  else
    dy1 = d23*cp1(2)
    dy2 = d13*cp2(2)
    dy3 = d12*cp3(2)
    a = (                -dy1 +                 dy2 -                 dy3)/det
    b = ( (cp2(1)+cp3(1))*dy1 - (cp1(1)+cp3(1))*dy2 + (cp1(1)+cp2(1))*dy3)/det
    c = ( -cp2(1)*cp3(1) *dy1 +  cp1(1)*cp3(1) *dy2 -  cp1(1)*cp2(1) *dy3)/det
    interparab = (a*x + b)*x + c
  endif
  
endfunction interparab
!------------------------------------------------------------------------------!


!------------------------------------------------------------------------------!
! Procedure : interpoltabsp/dp            Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  : Mars 2002
!   Interpolation selon un tableau d'entree (tabin) dans un tableau
!   contenant la liste des donnees dans la premiere dimension
!
! Defauts/Limitations/Divers :
!   L'ordre d'interpolation est parametrable, lineaire par defaut
!
!------------------------------------------------------------------------------!
subroutine interpoltabsp(tabin, tabout, ordre) ! donner une valeur par defaut a ordre

implicit none 

! -- Declaration des entrees --
real, dimension(:,:), intent(in) :: tabin      ! valeurs de reference
integer,              intent(in) :: ordre

! -- Declaration des sorties --
real, dimension(:,:), intent(inout) :: tabout  ! tableau interpole, contient des entrees

! -- Declaration des variables internes --
integer nin, nout, iin, iout

! -- Debut de la procedure --

  nin  = size( tabin, dim=1)       ! Verification de la taille du premier indice ?
  nout = size(tabout, dim=1)
  if (nin < 2) call interpolerr("Impossible d'interpoler dans un tableau a une valeur")
  iin = 2   ! pointe sur la valeur superieure de l'entree pour l'interpolation de chaque point
  do iout = 1, nout
    if (tabout(iout,1) > tabin(iin,1)) iin = min(nin, iin + 1)
    tabout(iout,2) = interlinsp(tabout(iout,1), tabin(iin-1,:), tabin(iin,:))
  enddo
 
endsubroutine interpoltabsp
!------------------------------------------------------------------------------!


!------------------------------------------------------------------------------!
subroutine interpoltabdp(tabin, tabout, ordre) ! donner une valeur par defaut a ordre

implicit none 

! -- Declaration des entrees --
double precision, dimension(:,:), intent(in) :: tabin      ! valeurs de reference
integer,                          intent(in) :: ordre

! -- Declaration des sorties --
double precision, dimension(:,:), intent(inout) :: tabout  ! resultat (:,2), entrees (:,1)

! -- Declaration des variables internes --
integer nin, nout, iin, iout

! -- Debut de la procedure --

  nin  = size( tabin, dim=1) 
  nout = size(tabout, dim=1)
  if (nin < 2) call interpolerr("Impossible d'interpoler dans un tableau a une valeur")
  iin = 2   ! pointe sur la valeur superieure de l'entree pour l'interpolation de chaque point
  do iout = 1, nout
    if (tabout(iout,1) > tabin(iin,1)) iin = min(nin, iin + 1)
    tabout(iout,2) = interlindp(tabout(iout,1), tabin(iin-1,:), tabin(iin,:))
  enddo
 
endsubroutine interpoltabdp
!------------------------------------------------------------------------------!


!------------------------------------------------------------------------------!
! Fonction : getfromtabsp/dp              Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  : Septembre 2002
!   Interpolation selon un tableau d'entree (tabin) une coordonnee unique
!
! Defauts/Limitations/Divers :
!   L'ordre d'interpolation est parametrable, lineaire par defaut
!
!------------------------------------------------------------------------------!
function getfromtabsp(xin, vin, coord, ordre)     ! donner une valeur par defaut a ordre

implicit none 

! -- Declaration des entrees --
real, dimension(:), intent(in) :: xin, vin   ! valeurs de reference
real,               intent(in) :: coord      ! entrees des coordonnees
integer, optional,  intent(in) :: ordre

! -- Declaration des sorties --
real :: getfromtabsp

! -- Declaration des variables internes --
integer nin, iin, iordre

! -- Debut de la procedure --

  if (present(ordre)) then
    iordre = ordre
  else
    iordre = 1
  endif

  nin  = size(xin, dim=1)

  if (size(vin,dim=1) /= nin) call interpolerr("Donnees d'entrees invalides")
  if (nin < 2) call interpolerr("Impossible d'interpoler dans un tableau a une valeur")

  iin = 2   ! pointe sur la valeur superieure de l'entree pour l'interpolation de chaque point
  do while ((coord > xin(iin)).and.(iin < nin)) 
    iin = iin + 1
  enddo

  getfromtabsp = interlinsp(coord, (/ xin(iin-1),vin(iin-1) /), (/ xin(iin),vin(iin) /) )
 
endfunction getfromtabsp
!------------------------------------------------------------------------------!

!------------------------------------------------------------------------------!
function getfromtabdp(xin, vin, coord, ordre)     ! donner une valeur par defaut a ordre

implicit none 

! -- Declaration des entrees --
double precision, dimension(:), intent(in) :: xin, vin   ! valeurs de reference
double precision,               intent(in) :: coord      ! entrees des coordonnees
integer, optional,              intent(in) :: ordre

! -- Declaration des sorties --
double precision :: getfromtabdp

! -- Declaration des variables internes --
integer nin, iin, iordre

! -- Debut de la procedure --

  if (present(ordre)) then
    iordre = ordre
  else
    iordre = 1
  endif

  nin  = size(xin, dim=1)

  if (size(vin,dim=1) /= nin) call interpolerr("Donnees d'entrees invalides")
  if (nin < 2) call interpolerr("Impossible d'interpoler dans un tableau a une valeur")

  iin = 2   ! pointe sur la valeur superieure de l'entree pour l'interpolation de chaque point
  do while ((coord > xin(iin)).and.(iin < nin)) 
    iin = iin + 1
  enddo

  getfromtabdp = interlindp(coord, (/ xin(iin-1), vin(iin-1) /), (/ xin(iin),vin(iin) /) )
 
endfunction getfromtabdp
!------------------------------------------------------------------------------!


!------------------------------------------------------------------------------!
! Fonction : getfromtabtsp/tdp            Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  : Mars 2002
!   Interpolation selon un tableau d'entree (tabin) et un tableau de coordonnees
!
! Defauts/Limitations/Divers :
!   L'ordre d'interpolation est parametrable, lineaire par defaut
!
!------------------------------------------------------------------------------!
function getfromtabtsp(xin, vin, coord, ordre)     ! donner une valeur par defaut a ordre

implicit none 

! -- Declaration des entrees --
real, dimension(:), intent(in) :: xin, vin   ! valeurs de reference
real, dimension(:), intent(in) :: coord      ! entrees des coordonnees
integer, optional,  intent(in) :: ordre

! -- Declaration des sorties --
real, dimension(size(coord,1))   :: getfromtabtsp

! -- Declaration des variables internes --
integer nin, nout, iin, iout, iordre

! -- Debut de la procedure --

  if (present(ordre)) then
    iordre = ordre
  else
    iordre = 1
  endif

  nin  = size(xin, dim=1)
  nout = size(coord, dim=1)
  !print*,"interpol:",nin,nout
  if (size(vin,dim=1) /= nin) call interpolerr("Donnees d'entrees invalides")
  if (nin < 2) call interpolerr("Impossible d'interpoler dans un tableau a une valeur")

  iin = 2   ! pointe sur la valeur superieure de l'entree pour l'interpolation de chaque point
  do iout = 1, nout
    do while ((coord(iout) > xin(iin)).and.(iin < nin)) 
      iin = iin + 1
    enddo
    getfromtabtsp(iout) = interlinsp(coord(iout), (/ xin(iin-1), vin(iin-1) /), &
                                                  (/ xin(iin),   vin(iin)   /)    )
  enddo
 
endfunction getfromtabtsp
!------------------------------------------------------------------------------!

!------------------------------------------------------------------------------!
function getfromtabtdp(xin, vin, coord, ordre)     ! donner une valeur par defaut a ordre

implicit none 

! -- Declaration des entrees --
double precision, dimension(:), intent(in) :: xin, vin   ! valeurs de reference
double precision, dimension(:), intent(in) :: coord      ! entrees des coordonnees
integer, optional,              intent(in) :: ordre

! -- Declaration des sorties --
double precision, dimension(size(coord,1))   :: getfromtabtdp

! -- Declaration des variables internes --
integer nin, nout, iin, iout, iordre

! -- Debut de la procedure --

  if (present(ordre)) then
    iordre = ordre
  else
    iordre = 1
  endif

  nin  = size(xin,   dim=1)
  nout = size(coord, dim=1)

  if (size(vin,dim=1) /= nin) call interpolerr("Donnees d'entrees invalides")
  if (nin < 2) call interpolerr("Impossible d'interpoler dans un tableau a une valeur")

  iin = 2   ! pointe sur la valeur superieure de l'entree pour l'interpolation de chaque point
  do iout = 1, nout
    do while ((coord(iout) > xin(iin)).and.(iin < nin)) 
      iin = iin + 1
    enddo
    getfromtabtdp(iout) = interlindp(coord(iout), (/ xin(iin-1), vin(iin-1) /), &
                                                  (/ xin(iin),   vin(iin)   /)    )
  enddo
 
endfunction getfromtabtdp
!------------------------------------------------------------------------------!


!------------------------------------------------------------------------------!
! Fonction : interlin                     Auteur : J. Gressier
!                                         Date   : Fevrier 2002
! Fonction                                Modif  :
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
!function interlin

!implicit none 

! -- Declaration des entrees --

! -- Declaration des sorties --

! -- Declaration des variables internes --

! -- Debut de la procedure --
  
!endsubroutine
!------------------------------------------------------------------------------!


endmodule INTERPOL

!------------------------------------------------------------------------------!
! Historique des modifications
!
! fev  2002 : creation de la procedure
!
!------------------------------------------------------------------------------!
