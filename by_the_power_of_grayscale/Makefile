all: build run

build: 
	docker build -t grayskull .

run: build
	docker run --name grayskull -p 80:80 -d grayskull

stop:
	docker stop grayskull

clean: stop
	docker rm grayskull
	docker image rm grayskull
