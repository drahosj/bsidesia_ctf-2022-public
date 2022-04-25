
DISTFILES=fuego.dis secrets.dis routines.dis
EXTRAFILES=setup.dis test.dis hiddenflag2.dis
MFILES=secrets.m routines.m


all: $(DISTFILES) $(EXTRAFILES)

install: $(DISTFILES)
	cp $(DISTFILES) $(MFILES) attachments/

%.dis: %.b
	limbo $<
	./disstrip.rb $@

clean:
	rm -f *.dis
