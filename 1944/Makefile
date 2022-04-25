all: 1944 solver install

install: 1944 attachments
	cp 1944 attachments/

attachments:
	mkdir attachments

%: %.d
	ldc2 $<

clean:
	rm -f 1944 solver fifo *.o

test: all fifo
	./solver < fifo | ./1944 > fifo

fifo:
	mkfifo fifo
