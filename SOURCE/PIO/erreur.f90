!------------------------------------------------------------------------------!
! Procedure : erreur                      Auteur : J. Gressier
!                                         Date   : Juillet 2002
! Fonction                                Modif  : 
!   Affichage d'une erreur et arr�t du programme
!   Ecriture sur unit� iout et fichier log 
!
!------------------------------------------------------------------------------!
subroutine erreur(str1, str2)
use OUTPUT
implicit none

! -- Declaration des entr�es --
integer          iout            ! numero d'unit� pour les erreurs
character(len=*) str1            ! cha�ne 1
character(len=*) str2            ! cha�ne 2

! -- Debut de la procedure --

write(uf_stdout,'(aaaaa)') "!!! Erreur ",trim(str1)," : ",trim(str2)," !!!"
write(uf_log,'(a)')    "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
write(uf_log,'(aaaa)')    "[STOP] Erreur ",trim(str1)," : ",trim(str2)

stop

endsubroutine erreur

