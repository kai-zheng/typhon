############################################################
##   Compilation de la librairie XIO

LDIR = XIO

####### Files

XIO_LIB = libt_xio.a

XIO_MOD = REPRISE.$(MOD)

XIO_OBJ = $(XIO_MOD:.$(MOD)=.o)  \
          output_tec_str.o  \
          output_tec_ust.o  \
          output_tecplot.o

D_XIO_OBJ = $(XIO_OBJ:%=$(PRJOBJ)/%)


####### Build rules

#all: $(PRJLIB)/$(XIO_LIB)

$(PRJLIB)/$(XIO_LIB): $(XIO_LIB)
	@echo \* Copie de la librairie $(XIO_LIB)
	@cp $(XIO_LIB) $(PRJLIB)

$(XIO_LIB): $(D_XIO_OBJ)
	@echo ---------------------------------------------------------------
	@echo \* Cr�ation de la librairie $(XIO_LIB)
	@touch $(XIO_LIB) ; rm $(XIO_LIB)
	@$(AR) ruv $(XIO_LIB) $(D_XIO_OBJ)
	@echo \* Cr�ation de l\'index de la librairie
	@$(RAN)    $(XIO_LIB)
	@echo ---------------------------------------------------------------
	@echo \* LIBRAIRIE $(XIO_LIB) cr��e
	@echo ---------------------------------------------------------------

XIO_clean:
	-rm  $(XIO_LIB) $(D_XIO_OBJ) $(XIO_MOD) || echo

####### Dependencies


XIO/depends.make: $(D_XIO_SRC)
	(cd XIO ; ../$(MAKEDEPENDS))

include XIO/depends.make



