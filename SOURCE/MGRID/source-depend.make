############################################################
##   Compilation de la librairie MGRID

LDIR := MGRID

####### Files

MGRID_LIB = $(PRJLIB)/libt_mgrid.a

MGRID_MOD = DEFFIELD.$(MOD)    \
            MGRID.$(MOD)


MGRID_OBJ = $(MGRID_MOD:.$(MOD)=.o)  \
            calc_gradient.o          \
            calc_gradient_limite.o  

D_MGRID_OBJ = $(MGRID_OBJ:%=$(PRJOBJ)/%)

D_MGRID_SRC := $(MGRID_OBJ:%.o=$(LDIR)/%.f90)

####### Build rules

all: $(MGRID_LIB)

$(MGRID_LIB): $(D_MGRID_OBJ)
	@echo ---------------------------------------------------------------
	@echo \* Cr�ation de la librairie $(MGRID_LIB)
	@touch $(MGRID_LIB) ; rm $(MGRID_LIB)
	@$(AR) ruv $(MGRID_LIB) $(D_MGRID_OBJ)
	@echo \* Cr�ation de l\'index de la librairie
	@$(RAN)    $(MGRID_LIB)
	@echo ---------------------------------------------------------------
	@echo \* LIBRAIRIE $(MGRID_LIB) cr��e
	@echo ---------------------------------------------------------------

MGRID_clean:
	-rm $(MGRID_LIB) $(D_MGRID_OBJ) $(MGRID_MOD)

####### Dependencies

MGRID/depends.make: $(D_MGRID_SRC)
	(cd MGRID ; ../$(MAKEDEPENDS))

include MGRID/depends.make

