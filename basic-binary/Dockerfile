FROM alpine:latest
RUN apk add busybox-extras build-base ldc
RUN echo "4444 stream tcp nowait root /str str" > /etc/inetd.conf
COPY str.c Makefile flag.txt /
RUN make str
EXPOSE 4444
CMD inetd -f
