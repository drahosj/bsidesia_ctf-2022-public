These are a few basic buffer overflows/binary exploits, intended to be easy.
Both are provided with source and a static binary.

The first one is just format string abuse, the second requires overwriting
the ret addr to jump to a preexisting give_flag fn.

Hidden flags in xattrs of the tarballs, and a super duper secret flag
for if they actually somehow shell out the buffer overflow one.
