####### Définition des catalogues

INCDIR  = $(HDIR)/LIB/Include
LIBDIR  = $(HDIR)/LIB/Lib
#PRJDIR  = $(HDIR)/TYPHON
PRJDIR  = .
PRJINC  = $(PRJDIR)/Include
PRJLIB  = $(PRJDIR)/Lib
PRJEXT  = $(PRJDIR)/LIBEXT
PRJOBJ  = $(PRJDIR)/Obj

####### Définition des utilitaires

AR          = ar
RAN         = touch
MAKE        = make
MAKEDEPENDS = Util/make_depends_low

####### Définitions des règles de compilation

.SUFFIXES: .f .f90 .$(MOD) .o


.f.o:
	@echo Il est anormal de passer par cette directive de compilation !!!
	$(CF) $(FF) -c $<

.f90.o:
	@echo Il est anormal de passer par cette directive de compilation !!!
	$(CF) $(FF) -c $< -o $(PRJOBJ)/$@

.f90:
	@echo TEST
	$(CF) $(FF) -c $< -o $(PRJOBJ)/$@

.f90.$(MOD):
	@echo Il est anormal de passer par cette directive de compilation !!!
	$(CF) $(FF) -c $<

$(PRJINC)/%.$(MOD): 
	@echo - MODULE : compiling file $*
	$(CF) $(FF) -c ${$*.source} -o $(PRJOBJ)/${$*.objet}
	@echo - transfert du module $*
	@mv $*.$(MOD) $(PRJINC)

$(PRJOBJ)/%.o: %.f90
	@echo - OBJECT : compiling file $*
	$(CF) $(FF) -c $< -o $(PRJOBJ)/$*.o

# intermédiaire pour les dépendances, garantissant la compilation
# %.dep: %.f90 
#	@echo - compilation du fichier $*
#	$(CF) $(FF) -c $< -o $(PRJOBJ)/$*.o
#	@touch $*.dep


