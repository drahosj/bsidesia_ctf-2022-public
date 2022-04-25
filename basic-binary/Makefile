all: str.tar.gz ret.tar.gz attachments/str.tar.gz attachments/ret.tar.gz

attachments/%: % attachments
	cp $< $@

str.tar.gz: str.c str
	tar --xattrs -cvzf str.tar.gz str.c str

str: str.c
	gcc -static -o str str.c
	setfattr -n user.flag -v SecDSM{sacando_un_pecho_fuera_al_puro_estilo_delacroix} str

ret.tar.gz: ret.c ret
	tar --xattrs -cvzf ret.tar.gz ret.c ret

ret: ret.c
	gcc -static -o ret ret.c
	setfattr -n user.flag -v SecDSM{no_sé_por_qué_dan_tanto_miedo_nuestras_tetas} ret

attachments:
	mkdir attachments

clean:
	rm -rf *.tar.gz str ret attachments
