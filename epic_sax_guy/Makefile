url.bin: flag.txt key.bin
	xor -k key.bin < flag.txt > url.bin

install: url.bin
	cp url.bin attachments/

clean:
	rm url.bin
