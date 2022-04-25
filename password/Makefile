all: run attachments attachments/run.d

attachments/run.d:
	cp run.d attachments/

attachments:
	mkdir attachments

run: run.d
	ldc2 run.d

clean:
	rm -rf run *.o attachments
