############################################################
##   MESH library compilation

LDIR := MESH

####### Files

# Library
MESH_LIB = $(PRJLIB)/libt_mesh.a

# Modules
MESH_MOD = ELEMVTEX.$(MOD)     \
           DEF_USTBOCO.$(MOD)  \
           GEO3D.$(MOD)        \
           GRID_CONNECT.$(MOD) \
           MESHBASE.$(MOD)     \
           STRMESH.$(MOD)      \
           TENSOR3.$(MOD)      \
           USTMESH.$(MOD)

# Objects
MESH_OBJ = $(MESH_MOD:.$(MOD)=.o)  \
           build_implicit_bdlu.o   \
           build_implicit_dlu.o    \
           calc_connface.o         \
           calc_ust_cell.o         \
           calc_ust_elemvol.o      \
           calc_ust_midcell.o      \
           calc_ust_checkface.o    \
           calc_ust_face.o         \
           calc_ustmesh.o          \
           init_implicit_bdlu.o    \
           init_implicit_dlu.o     \
           interpface_gradient_scal.o \
           interpface_gradient_vect.o \
           interpface_gradn_scal.o    \
           interpface_gradn_vect.o    \
           reorder_ustconnect.o    \
           scale_mesh.o            \
           test_ustmesh.o          \

D_MESH_OBJ = $(MESH_OBJ:%=$(PRJOBJ)/%)

D_MESH_SRC := $(MESH_OBJ:%.o=$(LDIR)/%.f90)


####### Build rules

all: $(MESH_LIB)

$(MESH_LIB): $(D_MESH_OBJ)
	@echo ---------------------------------------------------------------
	@echo \* Compiling library $(MESH_LIB)
	@touch $(MESH_LIB) ; rm $(MESH_LIB)
	@$(AR) ruv $(MESH_LIB) $(D_MESH_OBJ)
	@echo \* Creating library index
	@$(RAN)    $(MESH_LIB)
	@echo ---------------------------------------------------------------
	@echo \* LIBRARY $(MESH_LIB) created
	@echo ---------------------------------------------------------------

MESH_clean:
	-rm $(MESH_LIB) $(D_MESH_OBJ) $(MESH_MOD) MESH/depends.make


####### Dependencies

MESH/depends.make: $(D_MESH_SRC)
	(cd MESH ; ../$(MAKEDEPENDS))

include MESH/depends.make


