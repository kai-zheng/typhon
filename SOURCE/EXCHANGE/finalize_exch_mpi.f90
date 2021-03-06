!------------------------------------------------------------------------------!
! Procedure : finalize_exch                  Auteur : J. Gressier
!                                                 Date   : July 2004
! Fonction                                        Modif  : see history
!   Initialization of exchange protocol
!
! Defauts/Limitations/Divers :
!
!------------------------------------------------------------------------------!

subroutine finalize_exch(winfo)

use TYPHMAKE
use OUTPUT
use MODINFO

implicit none

#ifdef MPICOMPIL
include 'mpif.h'
#endif /*MPICOMPIL*/

! -- Declaration des entrees/sorties --
type(st_info) :: winfo

! -- Declaration des sorties --

! -- Declaration des variables internes --
integer :: ierr

! -- Debut de la procedure --


#ifdef MPICOMPIL
call print_info(5,"finalize MPI exchanges")

call MPI_Finalize(ierr)
#else  /*NO MPICOMPIL*/
call print_info(5,"finalize sequential exchanges")
#endif /*MPICOMPIL*/


endsubroutine finalize_exch

!------------------------------------------------------------------------------!
! Changes history
!
! july 2004 : creation de la procedure
!------------------------------------------------------------------------------!
