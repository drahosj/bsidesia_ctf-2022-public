flag.tar.gz: flag.zip password.txt
	tar cvzf flag.tar.gz --xattrs flag.zip password.txt

flag.zip: flag.txt pass.txt
	zip --encrypt -P $(file < pass.txt) flag.zip flag.txt

password.txt: pass.txt
	touch password.txt
	setfattr -n user.password -v $(file < pass.txt) password.txt

pass.txt:
	dd if=/dev/urandom count=8 bs=1 | xxd -p > pass.txt

clean:
	rm -f *.tar.gz *.zip password.txt pass.txt
