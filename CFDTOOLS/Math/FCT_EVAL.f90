!------------------------------------------------------------------------------!
! MODULE : FCT_EVAL                         Authors : J. Gressier
!                                           Date    : March 2006
! Evaluation of a function 
!
!------------------------------------------------------------------------------!
!> @ingroup FCT
!> @brief FCT function evaluation
!------------------------------------------------------------------------------!
module FCT_EVAL

use FCT_DEF
use FCT_ENV
use FCT_MATH

implicit none

! -- Constants -------------------------------------------

type(st_fct_env)   :: blank_env
     
! -- DECLARATIONS -----------------------------------------------------------

!------------------------------------------------------------------------------!
! structure ST_FCT_EVAL : 
!------------------------------------------------------------------------------!
!type st_fct_eval
!  integer                 :: type_node
!endtype st_fct_eval


! -- INTERFACES -------------------------------------------------------------

interface fct_eval_real
  module procedure fct_eval_real4, fct_eval_real8
end interface

interface fct_eval_realarray
  module procedure fct_eval_real4array, fct_eval_real8array
end interface

! -- Fonctions et Operateurs ------------------------------------------------


! -- IMPLEMENTATION ---------------------------------------------------------
contains

!------------------------------------------------------------------------------!
! fct_eval_real4
!------------------------------------------------------------------------------!
subroutine fct_eval_real4(env, fct, res)
implicit none

! -- parameters --
type(st_fct_env),       intent(in)  :: env     ! environment
type(st_fct_node),      intent(in)  :: fct     ! function to evaluate (base node)
real(4),                intent(out) :: res     ! real result

! -- internal variables --
type(st_fct_container)     :: cont             ! evaluation of container

  call fct_node_eval(env, fct, cont)
  select case(cont%type)
  case(cont_real)
    res = cont%r
  case default
    call set_fct_error(-1, "unexpected type of result (fct_eval_real4)")
  endselect
  call delete(cont)

end subroutine fct_eval_real4

!------------------------------------------------------------------------------!
! fct_eval_real8
!------------------------------------------------------------------------------!
subroutine fct_eval_real8(env, fct, res)
implicit none

! -- parameters --
type(st_fct_env),       intent(in)  :: env     ! environment
type(st_fct_node),      intent(in)  :: fct     ! function to evaluate (base node)
real(8),                intent(out) :: res     ! real result

! -- internal variables --
type(st_fct_container)     :: cont             ! evaluation of container

  call fct_node_eval(env, fct, cont)
  select case(cont%type)
  case(cont_real)
    res = cont%r
  case default
    call set_fct_error(-1, "unexpected type of result (fct_eval_real8)")
  endselect
  call delete(cont)

end subroutine fct_eval_real8

!------------------------------------------------------------------------------!
! fct_eval_real4array
!------------------------------------------------------------------------------!
subroutine fct_eval_real4array(env, fct, res)
implicit none

! -- parameters --
type(st_fct_env),       intent(in)  :: env     ! environment
type(st_fct_node),      intent(in)  :: fct     ! function to evaluate (base node)
real(4),                intent(out) :: res(:)  ! real result

! -- internal variables --
type(st_fct_container)     :: cont             ! evaluation of container

  call fct_node_eval(env, fct, cont)
  select case(cont%type)
  case(cont_real)
    res = cont%r
  case(cont_vect)
    res(1:cont%size) = cont%r_t(1:cont%size)
  case default
    call set_fct_error(-1, "unexpected type of result (fct_eval_real4array)")
  endselect
  call delete(cont)

end subroutine fct_eval_real4array

!------------------------------------------------------------------------------!
! fct_eval_real8array
!------------------------------------------------------------------------------!
subroutine fct_eval_real8array(env, fct, res)
implicit none

! -- parameters --
type(st_fct_env),       intent(in)  :: env     ! environment
type(st_fct_node),      intent(in)  :: fct     ! function to evaluate (base node)
real(8),                intent(out) :: res(:)  ! real result
! -- internal variables --
type(st_fct_container)     :: cont             ! evaluation of container

  call fct_node_eval(env, fct, cont)

  select case(cont%type)
  case(cont_real)
    res = cont%r
  case(cont_vect)
    res(1:cont%size) = cont%r_t(1:cont%size)
  case default
    call set_fct_error(-1, "unexpected type of result (fct_eval_real8array)")
  endselect
  call delete(cont)

end subroutine fct_eval_real8array

!------------------------------------------------------------------------------!
! fct_node_eval : eval and allocate container if needed
!------------------------------------------------------------------------------!
recursive subroutine fct_node_eval(env, fct, res)
implicit none

! -- parameters --
type(st_fct_env),       intent(in)  :: env     ! environment
type(st_fct_node),      intent(in)  :: fct     ! function to evaluate (base node)
type(st_fct_container), intent(out) :: res     ! container result

! -- internal variables --
type(st_fct_container)     :: left, right      ! evaluation of possible left & right operands
type(st_fct_node), pointer :: p

! -- body --

select case(fct%type_node)

case(node_cst)
  call copy_fct_container(fct%container, res)

case(node_var)
  ! should be evaluated in ENV
  call fct_env_seek_name(env, fct%container%name, p)
  if (associated(p)) then
    call copy_fct_container(p%container, res)
  else 
    call set_fct_error(-1, "variable "//trim(fct%container%name)//" not found in environment")
  endif

case(node_opunit)
  call fct_node_eval(env, fct%left, left)
  call fct_node_eval_opunit(env, fct%type_oper, left, res)
  call delete(left)

case(node_opbin)
  call fct_node_eval(env, fct%left,  left)
  call fct_node_eval(env, fct%right, right)
  call fct_node_eval_opbin(env, fct%type_oper, left, right, res)
  call delete(left)
  call delete(right)

case default
  call set_fct_error(-1, "unknown NODE type in FCT_EVAL")
endselect

endsubroutine fct_node_eval


!------------------------------------------------------------------------------!
! fct_node_eval_opbin
!------------------------------------------------------------------------------!
subroutine fct_node_eval_opbin(env, type_oper, left, right, res)
implicit none

! -- parameters --
type(st_fct_env),       intent(in)  :: env
integer(ipar),          intent(in)  :: type_oper     ! type of binary operator
type(st_fct_container), intent(in)  :: left, right   ! both operands
type(st_fct_container), intent(out) :: res           ! container result

! -- internal variables --

! -- body --

select case(type_oper)
case(op_add)
  call fct_cont_add(res, left, right)
case(op_sub)
  call fct_cont_sub(res, left, right)
case(op_mul)
  call fct_cont_mul(res, left, right)
case(op_div)
  call fct_cont_div(res, left, right)
case(op_pow)
  call fct_cont_pow(res, left, right)
case default
  call set_fct_error(-1, "unknown or non-implemented BINARY OPERATOR in FCT_EVAL")
endselect

endsubroutine fct_node_eval_opbin


!------------------------------------------------------------------------------!
! fct_node_eval_opunit
!------------------------------------------------------------------------------!
subroutine fct_node_eval_opunit(env, type_oper, operand, res)
implicit none

! -- parameters --
type(st_fct_env),       intent(in)  :: env
integer(ipar),          intent(in)  :: type_oper     ! type of unary operator
type(st_fct_container), intent(in)  :: operand       ! operand 
type(st_fct_container), intent(out) :: res           ! container result

! -- internal variables --

! -- body --

select case(type_oper)
case(fct_opp)
  call fct_cont_opp(res, operand)
case(fct_inv)
  call fct_cont_inv(res, operand)
case(fct_sqr)
  call fct_cont_sqr(res, operand)
case(fct_sqrt)
  call fct_cont_sqrt(res, operand)
case(fct_exp)
  call fct_cont_exp(res, operand)
case(fct_ln)
  call fct_cont_ln(res, operand)
case(fct_log)
  call fct_cont_log(res, operand)
case(fct_sin)
  call fct_cont_sin(res, operand)
case(fct_cos)
  call fct_cont_cos(res, operand)
case(fct_tan)
  call fct_cont_tan(res, operand)
case(fct_sinh)
  call fct_cont_sinh(res, operand)
case(fct_cosh)
  call fct_cont_cosh(res, operand)
case(fct_tanh)
  call fct_cont_tanh(res, operand)
case(fct_asin)
  call fct_cont_asin(res, operand)
case(fct_acos)
  call fct_cont_acos(res, operand)
case(fct_atan)
  call fct_cont_atan(res, operand)
case(fct_asinh)
  call fct_cont_asinh(res, operand)
case(fct_acosh)
  call fct_cont_acosh(res, operand)
case(fct_atanh)
  call fct_cont_atanh(res, operand)
case(fct_erf)
  call fct_cont_erf(res, operand)
case(fct_erfc)
  call fct_cont_erfc(res, operand)
case(fct_abs)
  call fct_cont_abs(res, operand)
case(fct_sign)
  call fct_cont_inv(res, operand)
case(fct_step)
  call fct_cont_step(res, operand)
case(fct_ramp)
  call fct_cont_ramp(res, operand)
case default
  call set_fct_error(-1, "unknown or non-implemented UNARY OPERATOR in FCT_MATH")
endselect

endsubroutine fct_node_eval_opunit


!------------------------------------------------------------------------------!
endmodule FCT_EVAL
!------------------------------------------------------------------------------!
! Changes history
!
! May  2006 : module creation
! July 2006 : evaluation of fct_node tree with real operands only
!------------------------------------------------------------------------------!
