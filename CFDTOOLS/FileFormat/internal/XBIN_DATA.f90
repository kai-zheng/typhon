!------------------------------------------------------------------------------!
! MODULE : XBIN_DATA
!
!------------------------------------------------------------------------------!
module XBIN_DATA

use IOCFD
use XBIN_IO

implicit none

! -- Global Variables -------------------------------------------

integer, parameter :: xbin_namelen = 32
! -- datatype --

integer(xbinkpp),   parameter :: xbindatatype_undefined      = -1   !
integer(xbinkpp),   parameter :: xbindatatype_nodata         = 1    !
integer(xbinkpp),   parameter :: xbindatatype_int_ordarray   = 10   !          ordered int  array
integer(xbinkpp),   parameter :: xbindatatype_int_indarray   = 15   ! indirect ordered int  array
integer(xbinkpp),   parameter :: xbindatatype_real_ordarray  = 20   !          ordered real array
integer(xbinkpp),   parameter :: xbindatatype_real_indarray  = 25   ! indirect ordered real array



! -- DECLARATIONS -----------------------------------------------------------

private xbin_writedatahead

interface xbin_writedata_ordint
  module procedure xbin_writedata_ordint_x, xbin_writedata_ordint_xx
endinterface

interface xbin_writedata_indint
  module procedure xbin_writedata_indint_xx
endinterface

interface xbin_writedata_ordreal
  module procedure xbin_writedata_ordreal_xx
endinterface

!------------------------------------------------------------------------------!
! Structures
!------------------------------------------------------------------------------!
type st_xbindatasection
  character(len=xbin_namelen) :: name                                 ! data section name
  integer(xbinkpp)            :: datatype   = xbindatatype_undefined  ! XBIN type of data
  integer(xbinkpp)            :: groupindex                           ! NOT YET USED
  integer(xbinkpp)            :: usertype                             ! user-defined type of data
  integer(xbinkpp)            :: intsize                              ! binary size of integers
  integer(xbinkpp)            :: realsize                             ! binary size of reals
  integer(xbinkpp)            :: nparam                               ! number of  int parameters
  integer(xbinkip), pointer   :: param(:)                             ! additional int parameters
  integer(xbinkip)            :: dim, nelem, firstindex               ! size of DATA arrays
                                                                      !   data(dim, nelem)
                                                                      !   index(nelem)
  integer(xbinkip) :: expected_totdatasize  ! expected size after header
  integer(xbinkip) :: current_totdatasize
endtype st_xbindatasection


contains 
!------------------------------------------------------------------------------!


!------------------------------------------------------------------------------!
! data type name
!------------------------------------------------------------------------------!
function xbindataname(xbindata) result(strout)
implicit none
! -- INPUTS --
type(st_xbindatasection) :: xbindata
! -- OUTPUTS --
character(len=30) :: strout
! -- private data --

  select case(xbindata%datatype)
  case(xbindatatype_nodata)
    strout = "no data"
  case(xbindatatype_int_ordarray)
    strout = "ordered integer array"
  case(xbindatatype_int_indarray)
    strout = "indexed integer array"
  case(xbindatatype_real_ordarray)
    strout = "ordered real array"
  case(xbindatatype_real_indarray)
    strout = "indexed real array"
  case default
     call cfd_error(xbin_prefix//"unknown data type") 
  endselect

endfunction xbindataname


!------------------------------------------------------------------------------!
! delete xbindatasection
!------------------------------------------------------------------------------!
subroutine delete_xbindata(xbindata)
implicit none
! -- INPUTS --
! -- OUTPUTS --
type(st_xbindatasection) :: xbindata
! -- private data --

xbindata%groupindex      = 0
xbindata%usertype        = 0
xbindata%nparam          = 0
if (associated(xbindata%param)) deallocate(xbindata%param)

endsubroutine delete_xbindata


!------------------------------------------------------------------------------!
! read and write HEADER
!------------------------------------------------------------------------------!
subroutine xbin_defdatasection(xbindata, usertype, name, param)
implicit none
! -- INPUTS --
integer(xbinkpp)           :: usertype
character(len=*)           :: name
integer(xbinkip), optional :: param(:)
! -- OUTPUTS --
type(st_xbindatasection) :: xbindata
! -- private data --

xbindata%name            = name
xbindata%groupindex      = 0
xbindata%intsize         = xbinkip
xbindata%realsize        = xbinkrp
xbindata%usertype        = usertype
if (present(param)) then
  xbindata%nparam          = size(param)
  allocate(xbindata%param(1:xbindata%nparam))
  xbindata%param(1:xbindata%nparam) = param(1:xbindata%nparam)
else
  xbindata%nparam          = 0
  nullify(xbindata%param)
endif

endsubroutine xbin_defdatasection


!------------------------------------------------------------------------------!
! read DATA section
!------------------------------------------------------------------------------!
subroutine xbin_readdatahead(defxbin, xbindata)
implicit none
! -- INPUTS --
type(st_defxbin)         :: defxbin
type(st_xbindatasection) :: xbindata
! -- OUTPUTS --
! -- private data --
integer :: info

  read(defxbin%iunit) xbindata%datatype  
  read(defxbin%iunit) xbindata%name
  read(defxbin%iunit) xbindata%groupindex
  read(defxbin%iunit) xbindata%usertype
  read(defxbin%iunit) xbindata%intsize
  if (xbindata%intsize /= xbinkip) &
     call cfd_error(xbin_prefix//"unexpected integer size in file") 
  read(defxbin%iunit) xbindata%realsize
  if (xbindata%realsize /= xbinkrp) &
     call cfd_error(xbin_prefix//"unexpected real size in file") 
  read(defxbin%iunit) xbindata%nparam
  if (xbindata%nparam >= 1) then
    allocate(xbindata%param(1:xbindata%nparam))
    read(defxbin%iunit) xbindata%param(1:xbindata%nparam)
  else
    nullify(xbindata%param)
  endif

  select case(xbindata%datatype)
  case(xbindatatype_nodata)
    ! nothing to do
  case(xbindatatype_int_ordarray, xbindatatype_real_ordarray)
    read(defxbin%iunit) xbindata%firstindex, xbindata%nelem, xbindata%dim
  case(xbindatatype_int_indarray, xbindatatype_real_indarray)
    read(defxbin%iunit) xbindata%nelem, xbindata%dim
  case default
     call cfd_error(xbin_prefix//" unknown data type (xbin_readdatahead)") 
  endselect

endsubroutine xbin_readdatahead

!------------------------------------------------------------------------------!
! write DATA section
!------------------------------------------------------------------------------!
subroutine xbin_writedatahead(defxbin, xbindata)
implicit none
! -- INPUTS --
type(st_defxbin)         :: defxbin
type(st_xbindatasection) :: xbindata
! -- OUTPUTS --
! -- private data --
integer :: info

  if (xbindata%datatype <= 0) then
    call cfd_error(xbin_prefix//" unknown data type (xbin_writedatahead)")
  endif

  write(defxbin%iunit) xbindata%datatype,   &
                       xbindata%name,       &
                       xbindata%groupindex, &
                       xbindata%usertype,   &
                       xbindata%intsize,    &
                       xbindata%realsize,   &
                       xbindata%nparam
  if (xbindata%nparam >= 1) then
    write(defxbin%iunit) xbindata%param(1:xbindata%nparam)
  endif

endsubroutine xbin_writedatahead

!------------------------------------------------------------------------------!
! skip DATA section
!------------------------------------------------------------------------------!
subroutine xbin_skipdata(defxbin, xbindata)
implicit none
! -- INPUTS --
type(st_defxbin)         :: defxbin
type(st_xbindatasection) :: xbindata
! -- OUTPUTS --
! -- private data --
integer          :: info
integer(xbinkip), allocatable :: iarray(:)
real(xbinkrp),    allocatable :: rarray(:)

  select case(xbindata%datatype)
  case(xbindatatype_nodata)
    call xbin_readend(defxbin)
  case(xbindatatype_int_ordarray)
    allocate(iarray(xbindata%nelem*max(1,xbindata%dim)))
    read(defxbin%iunit) iarray
    deallocate(iarray)
    call xbin_readend(defxbin)
  case(xbindatatype_int_indarray)
    allocate(iarray(xbindata%nelem*(max(1,xbindata%dim)+1)))
    read(defxbin%iunit) iarray
    deallocate(iarray)
    call xbin_readend(defxbin)
  case(xbindatatype_real_ordarray)
    allocate(rarray(xbindata%nelem*max(1,xbindata%dim)))
    read(defxbin%iunit) rarray
    deallocate(rarray)
    call xbin_readend(defxbin)
  case(xbindatatype_real_indarray)
    allocate(iarray(xbindata%nelem))
    allocate(rarray(xbindata%nelem*max(1,xbindata%dim)))
    read(defxbin%iunit) iarray
    read(defxbin%iunit) rarray
    deallocate(iarray)
    deallocate(rarray)
    call xbin_readend(defxbin)
  case default
     call cfd_error(xbin_prefix//" unknown data type (xbin_skipdata)") 
  endselect

endsubroutine xbin_skipdata


!------------------------------------------------------------------------------!
! write DATA section (no data)
!------------------------------------------------------------------------------!
subroutine xbin_writedata_nodata(defxbin, xbindata)
implicit none
! -- INPUTS --
type(st_defxbin)         :: defxbin
type(st_xbindatasection) :: xbindata
! -- OUTPUTS --
! -- private data --
integer :: info

  xbindata%datatype = xbindatatype_nodata
  call xbin_writedatahead(defxbin, xbindata)

  call xbin_writeend(defxbin)

endsubroutine xbin_writedata_nodata


!------------------------------------------------------------------------------!
! write DATA section (integer array with implicit ordered index)
!------------------------------------------------------------------------------!
subroutine xbin_writedata_ordint_x(defxbin, xbindata, nelem, array, firstindex)
implicit none
! -- INPUTS --
type(st_defxbin)           :: defxbin
type(st_xbindatasection)   :: xbindata
integer(xbinkip)           :: nelem
integer(xbinkip), optional :: firstindex
integer(xbinkip)           :: array(1:nelem)
! -- OUTPUTS --
! -- private data --
integer(xbinkip) :: i1, dim

  dim = 0
  i1  = 1
  if (present(firstindex)) i1 = firstindex

  xbindata%datatype = xbindatatype_int_ordarray
  call xbin_writedatahead(defxbin, xbindata)

  write(defxbin%iunit) i1, nelem, dim
  write(defxbin%iunit) array(1:nelem)

  call xbin_writeend(defxbin)
  
endsubroutine xbin_writedata_ordint_x


!------------------------------------------------------------------------------!
! write DATA section (integer array with implicit ordered index)
!------------------------------------------------------------------------------!
subroutine xbin_writedata_ordint_xx(defxbin, xbindata, nelem, dim, array, firstindex)
implicit none
! -- INPUTS --
type(st_defxbin)           :: defxbin
type(st_xbindatasection)   :: xbindata
integer(xbinkip)           :: nelem, dim
integer(xbinkip), optional :: firstindex
integer(xbinkip)           :: array(1:dim, 1:nelem)
! -- OUTPUTS --
! -- private data --
integer(xbinkip) :: i1

  i1 = 1
  if (present(firstindex)) i1 = firstindex

  xbindata%datatype = xbindatatype_int_ordarray
  call xbin_writedatahead(defxbin, xbindata)

  write(defxbin%iunit) i1, nelem, dim
  write(defxbin%iunit) array(1:dim, 1:nelem)

  call xbin_writeend(defxbin)
  
endsubroutine xbin_writedata_ordint_xx

!------------------------------------------------------------------------------!
! write DATA section (integer array with indirect index)
!------------------------------------------------------------------------------!
subroutine xbin_writedata_indint_xx(defxbin, xbindata, nelem, iindex, dim, iarray)
implicit none
! -- INPUTS --
type(st_defxbin)         :: defxbin
type(st_xbindatasection) :: xbindata
integer(xbinkip)         :: nelem, dim
integer(xbinkip)         :: iindex(1:nelem)
integer(xbinkip)         :: iarray(1:dim, 1:nelem)
! -- OUTPUTS --
! -- private data --
integer :: info

  xbindata%datatype = xbindatatype_int_indarray
  call xbin_writedatahead(defxbin, xbindata)

  write(defxbin%iunit) nelem, dim
  write(defxbin%iunit) iindex(1:nelem)
  write(defxbin%iunit) iarray(1:dim, 1:nelem)

  call xbin_writeend(defxbin)
  
endsubroutine xbin_writedata_indint_xx


!------------------------------------------------------------------------------!
! write DATA section (real array with implicit ordered index)
!------------------------------------------------------------------------------!
subroutine xbin_writedata_ordreal_xx(defxbin, xbindata, nelem, dim, array, firstindex)
implicit none
! -- INPUTS --
type(st_defxbin)           :: defxbin
type(st_xbindatasection)   :: xbindata
integer(xbinkip)           :: nelem, dim
integer(xbinkip), optional :: firstindex
real(xbinkrp)              :: array(1:dim, 1:nelem)
! -- OUTPUTS --
! -- private data --
integer(xbinkip) :: i1

  i1 = 1
  if (present(firstindex)) i1 = firstindex

  xbindata%datatype = xbindatatype_real_ordarray
  call xbin_writedatahead(defxbin, xbindata)

  write(defxbin%iunit) i1, nelem, dim
  write(defxbin%iunit) array(1:dim, 1:nelem)

  call xbin_writeend(defxbin)
  
endsubroutine xbin_writedata_ordreal_xx



endmodule XBIN_DATA
!------------------------------------------------------------------------------!
! Changes
!
! June 2010: 
!------------------------------------------------------------------------------!
