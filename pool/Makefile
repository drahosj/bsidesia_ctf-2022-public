all: mystery.png

mystery.png: mystery-initial.png
	convert $< -set comment 'SecDSM{vote_for_the_winners}' $@

mystery-initial.png: mystery.svg
	convert -size 2000x2000 $< $@

mystery.svg: mystery.hex poolhex.xsl
	saxon9 -xsl:poolhex.xsl -s:$< -o:$@

mystery.hex:
	echo "SecDSM{are_you_the_winners}" | xxd -p | ./hex2xml > $@

clean:
	rm -f *.png *.svg *.hex
