#----------------------------------------------------------------------
# tymon_plot.tcl                                     J�r�mie Gressier
#                                                        July 2004
# Plot functions
#----------------------------------------------------------------------
# 07/2004 : created
#----------------------------------------------------------------------


#----------------------------------------------------------------------
# plot:change_var : 
#----------------------------------------------------------------------
proc plot:change_var {  } {
  global guicolor guivar

} ;# fin proc plot:change_var

#----------------------------------------------------------------------
# plot:toggle_var : 
#----------------------------------------------------------------------
proc plot:toggle_var { plot var } {
  global guicolor guivar gplot

  puts $plot:$var:$gplot($gplot:$var)

} ;# fin proc plot:toggle_var


