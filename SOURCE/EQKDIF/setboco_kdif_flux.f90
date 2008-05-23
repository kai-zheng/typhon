!------------------------------------------------------------------------------!
! Procedure : setboco_kdif_flux           Authors: J. Gressier/E. Radenac
!                                         Date   : Juin 2004
! Function                                Modif  : (cf Historique)
!   Computation of non-uniform boundary conditions for solid, wall with set
!   heat flux
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!
subroutine setboco_kdif_flux(curtime, unif, ustboco, ustdom, champ, defsolver, bckdif, defspat)

use TYPHMAKE
use OUTPUT
use VARCOM
use MENU_SOLVER
use MENU_BOCO
use USTMESH
use DEFFIELD 
use MENU_NUM
use FCT_EVAL
use FCT_ENV

implicit none

! -- Inputs --
real(krp)          :: curtime          ! current time
integer            :: unif             ! uniform or not
type(st_ustboco)   :: ustboco          ! boundary conditions
type(st_ustmesh)   :: ustdom           ! unstructured mesh
type(mnu_solver)   :: defsolver        ! kind of solver
type(st_boco_kdif) :: bckdif           ! parameters and fluxes (field or constant)
type(mnu_spat)     :: defspat

! -- Outputs --
type(st_field)   :: champ            ! field

! -- Internal variables --
integer          :: ifb, if, ip   ! index of list, index de boundary face and parameters
integer          :: nface
integer          :: ic, ighost    ! index of inner cells and factice cells
type(v3d)        :: cgface, cg, normale ! face, cell center, face normale
real(krp)        :: d             ! distance cell - boundary face
real(krp)        :: conduct       ! conductivity
type(v3d)        :: gradT         ! temperature gradient
type(v3d)        :: dc            ! vector cell center - its projection 
                                  ! on the face normale
real(krp)        :: gTdc          ! scalar product gradT.dc
real(krp), pointer :: lflux(:)

! -- BODY --

nface = ustboco%nface 

allocate(lflux(nface))
call new_fct_env(blank_env)      ! temporary environment from FCT_EVAL

select case(unif)
case(uniform)
  
  do ifb = 1, nface
     if     = ustboco%iface(ifb)
     call fct_env_set_real(blank_env, "x", ustdom%mesh%iface(if,1,1)%centre%x)
     call fct_env_set_real(blank_env, "y", ustdom%mesh%iface(if,1,1)%centre%y)
     call fct_env_set_real(blank_env, "z", ustdom%mesh%iface(if,1,1)%centre%z)
     call fct_env_set_real(blank_env, "t", curtime)
     call fct_eval_real(blank_env, bckdif%wall_flux, lflux(ifb))
  enddo
  lflux = -lflux  !!! USER flux is entering the domain (so, must be reversed)

case(nonuniform)
  lflux(1:nface) = bckdif%flux_nunif(1:nface)

case default
  call erreur("boco flux computation","unknown definition")
endselect

!-------------------------------------------------------------
! APPLY FLUX CONDITION

do ifb = 1, nface

  if     = ustboco%iface(ifb)
  ic     = ustdom%facecell%fils(if,1)
  ighost = ustdom%facecell%fils(if,2)

  ! Computation of distance cell center - face center
  cgface = ustdom%mesh%iface(if,1,1)%centre
  cg     = ustdom%mesh%centre(ic,1,1)
  normale= ustdom%mesh%iface(if,1,1)%normale
! d    = (cgface - cg) .scal. (cgface - cg) / (abs((cgface - cg).scal.normale))
  d = abs( (cgface - cg).scal.normale )

  ! Conductivity
  conduct = valeur_loi(defsolver%defkdif%materiau%Kd, champ%etatprim%tabscal(1)%scal(ic))

  ! Heat flux
  ustboco%bocofield%tabscal(1)%scal(ifb) = ustboco%bocofield%tabscal(1)%scal(ifb) + lflux(ifb)

  ! Approximated temperature in factice cell, for computation of gradients
  dc = (cgface - cg) - ( (cgface - cg).scal.normale ) * normale
  !if (defspat%calc_grad) then
  !  gradT = champ%gradient%tabvect(1)%vect(ic)
  !  gTdc = gradT .scal. dc
  !  champ%etatprim%tabscal(1)%scal(ighost) = &
  !         champ%etatprim%tabscal(1)%scal(ic) + gTdc - lflux(ifb)*d/conduct
  !else
    d = (cgface - cg) .scal. (cgface - cg) / (abs((cgface - cg).scal.normale))
    champ%etatprim%tabscal(1)%scal(ighost) = &
           champ%etatprim%tabscal(1)%scal(ic) - lflux(ifb)*d/conduct

  !endif


enddo


deallocate(lflux)

endsubroutine setboco_kdif_flux

!------------------------------------------------------------------------------!
! Change history
!
! june 2004 : creation 
! july 2004 : merge of uniform and non-uniform boco settings
! Mar  2008 : use of FCT function
! May  2008 : delete use of gradient in temperature estimate
!------------------------------------------------------------------------------!
