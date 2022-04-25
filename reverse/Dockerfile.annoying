FROM alpine:latest
RUN apk add busybox-extras build-base ldc
RUN echo "4444 stream tcp nowait root /1944 1944" > /etc/inetd.conf
COPY 1944.d Makefile flag.txt /
RUN make 1944
EXPOSE 4444
CMD inetd -f
