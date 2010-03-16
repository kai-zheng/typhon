!------------------------------------------------------------------------------!
! Procedure : setboco_ns_inlet_sub        Auteur : J. Gressier
!                                         Date   : July 2004
! Fonction   
!   Computation of supersonic inlet boundary conditions
!   
!------------------------------------------------------------------------------!
subroutine setboco_ns_inlet_sub(curtime, defns, unif, bc_ns, ustboco, umesh, fld)

use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_BOCO
use USTMESH
use DEFFIELD 
use FCT_EVAL
use FCT_ENV

implicit none

! -- INPUTS --
real(krp)        :: curtime
type(mnu_ns)     :: defns            ! solver parameters
integer          :: unif             ! uniform or not
type(st_boco_ns) :: bc_ns            ! parameters (field or constant)
type(st_ustboco) :: ustboco          ! lieu d'application des conditions aux limites
type(st_ustmesh) :: umesh            ! maillage non structure

! -- OUTPUTS --
type(st_field)   :: fld              ! fld des etats

! -- Internal variables --
integer                :: ifb, if, ip, nf  ! index de liste, index de face limite et parametres
integer                :: ic, ighost    ! index de cellule interieure, et de cellule fictive
real(krp), allocatable :: ps(:), pi(:), ti(:)
type(v3d), allocatable :: dir(:)
type(st_nsetat) :: nspri

! -- BODY --

if (unif /= uniform) call erreur("Developpement","Condition non uniforme non implementee")

call new_fct_env(blank_env)      ! temporary environment from FCT_EVAL

nf = ustboco%nface

call new(nspri, nf)
allocate(ps(nf))
allocate(pi(nf))
allocate(ti(nf))
allocate(dir(nf))

dir(1:nf) = bc_ns%direction

call fct_env_set_real(blank_env, "t", curtime)

do ifb = 1, nf
  if   = ustboco%iface(ifb)
  ic   = umesh%facecell%fils(if,1)
  ps(ifb) = fld%etatprim%tabscal(2)%scal(ic)
  call fct_env_set_real(blank_env, "x", umesh%mesh%iface(if,1,1)%centre%x)
  call fct_env_set_real(blank_env, "y", umesh%mesh%iface(if,1,1)%centre%y)
  call fct_env_set_real(blank_env, "z", umesh%mesh%iface(if,1,1)%centre%z)
  call fct_eval_real(blank_env, bc_ns%ptot, pi(ifb))
  call fct_eval_real(blank_env, bc_ns%ttot, ti(ifb))
enddo

call pi_ti_ps_dir2nspri(defns%properties(1), nf, pi(1:nf), ti(1:nf), ps(1:nf), dir(1:nf), &
                        nspri) 

do ifb = 1, nf
  if      = ustboco%iface(ifb)
  ighost  = umesh%facecell%fils(if,2)
  fld%etatprim%tabscal(1)%scal(ighost) = nspri%density(ifb)
  fld%etatprim%tabscal(2)%scal(ighost) = nspri%pressure(ifb)
  fld%etatprim%tabvect(1)%vect(ighost) = nspri%velocity(ifb)
enddo

call delete(nspri)
deallocate(ps, pi, ti, dir)

endsubroutine setboco_ns_inlet_sub

!------------------------------------------------------------------------------!
! Changes history
!
! july 2004 : creation
! June 2008 : FCT function for pi, ti, mach (function of X, Y, Z)
! Mar  2010 : time dependent conditions
!------------------------------------------------------------------------------!
