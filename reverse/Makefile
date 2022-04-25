all: reverse annoying easy
	
install: attachments/reverse attachments/annoying attachments/easy

attachments/%: % attachments
	cp $< attachments/

%: %.c
	gcc -o $@ $<

attachments:
	mkdir attachments

clean:
	rm -rf *.o reverse attachments/ annoying easy
