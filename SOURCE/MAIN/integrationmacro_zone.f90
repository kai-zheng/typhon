!------------------------------------------------------------------------------!
! Procedure : integrationmacro_zone       Auteur : J. Gressier
!                                         Date   : Juillet 2002
! Fonction                                Modif  : (cf Historique)
!   Int�gration d'une zone sur un �cart de temps donn�,
!   d'une repr�sentation physique uniquement
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine integrationmacro_zone(lzone)

use TYPHMAKE
use OUTPUT
use VARCOM
use DEFZONE
use DEFFIELD
use GEO3D

implicit none

! -- Declaration des entr�es --
type(st_zone) :: lzone            ! zone � int�grer

! -- Declaration des sorties --

! -- Declaration des variables internes --
real(krp)   :: local_t            ! temps local (0 � mdt)
real(krp)   :: dt                 ! pas de temps de la zone
integer     :: iter               ! num�ro d'it�ration local au cycle
integer     :: if                 ! index de champ
real(krp)   :: fourier
logical     :: fin

! -- Debut de la procedure --

iter    = 0
local_t = 0._krp
fin     = .false.

! �criture d'informations

select case(lzone%info%typ_temps)

case(stationnaire)
  write(str_w,'(a,i5)') "  zone",lzone%id

case(instationnaire)
  write(str_w,'(a,i5,a,g10.4)') "  zone",lzone%id," � t local =",local_t
  
case(periodique)

endselect

call print_info(7,str_w)

!----------------------------------
! int�gration
!----------------------------------

do while (.not.fin)

  iter = iter + 1
  
  ! ---
  call calc_zonetimestep(lzone, dt)
  ! ---

  ! �criture d'informations et gestion

  select case(lzone%info%typ_temps)

  case(stationnaire)

  case(instationnaire)
    if (dt >= (lzone%info%cycle_dt - local_t)) then
      fin = .true.
      dt  = lzone%info%cycle_dt - local_t
    endif  
  
  case(periodique)

  endselect

  ! On peut ici coder diff�rentes m�thodes d'int�gration (RK, temps dual...)

  ! ---
  call integration_zone(dt, lzone)
  ! ---

  do if = 1, lzone%ndom
    call update_champ(lzone%info, lzone%field(if), lzone%ust_mesh%ncell_int)  ! m�j    des var. conservatives
    call calc_varprim(lzone%defsolver, lzone%field(if))     ! calcul des var. primitives
    call calc_gradient(lzone%defsolver, lzone%ust_mesh,                 &
                       lzone%field(if)%etatprim, lzone%field(if)%gradient)
  enddo

  ! �criture d'informations

  select case(lzone%info%typ_temps)

  case(stationnaire)
    lzone%info%residu_ref = max(lzone%info%residu_ref, lzone%info%cur_res)
    if (lzone%info%cur_res/lzone%info%residu_ref <= lzone%info%residumax) fin = .true.
    write(str_w,'(a,i5,a,g10.4)') "    iteration",iter," | residu = ", &
                                  log10(lzone%info%cur_res/lzone%info%residu_ref)

  case(instationnaire)
    local_t = local_t + dt
    write(str_w,'(a,i5,a,g10.4)') "    integration",iter," � t local =",local_t
  
  case(periodique)

  endselect

  call print_info(9,str_w)

enddo

call capteurs(lzone)

!---------------------------------------
endsubroutine integrationmacro_zone

!------------------------------------------------------------------------------!
! Historique des modifications
!
! juil  2002  : cr�ation de la proc�dure
! juin  2003  : champs multiples
! juil  2003  : calcul du nombre de Fourier de la zone 
!               allocation des residus remont�e � integration_macrodt
! sept  2003
!------------------------------------------------------------------------------!
