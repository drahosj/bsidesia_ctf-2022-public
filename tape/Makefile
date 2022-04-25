flag.wav: flag.dat
	minimodem --tx -f flag.wav --ascii 100 < flag.dat

flag.dat: flag.png flag.md5 pad
	cat flag.md5 pad flag.md5 pad flag.md5 pad > flag.dat
	cat flag.png.gz pad flag.png.gz pad >> flag.dat

pad:
	dd if=/dev/zero of=pad bs=1 count=16

flag.md5: flag.png.gz
	md5sum flag.png.gz > flag.md5

flag.png.gz: flag.png
	gzip flag.png

flag.png: qrcode-flag.txt metadata-flag.txt
	qrencode -r qrcode-flag.txt -o flag.png
	exiftool "-comment=`cat metadata-flag.txt`" flag.png

clean:
	rm -f flag.png *.md5 *.wav pad *.dat *.png_original *.gz
