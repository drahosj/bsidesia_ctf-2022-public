# By the Power of Grayscale

## Description

10 part ctf challenge plus additional hidden flag

## Learning potential

- HTTP request/response headers
- HTML source
- Image metadata & manipulation
- website directory exploration and enumeration
- .git vulnerabilities
- git repo exploration
- github repo exploration
- golang module tracking
- understanding golang source

## Theory of Operation

Challange presents as a docker image exposing port 80. Inside is an nginx instance
handling static files as well as a running golang binary listening internally on 
port 8000. Specific nginx paths will proxy to the golang binary.

## Requirements & Installation

### Requirements

- docker / podman
- external ip

### make build

Build the container and label it `grayskull`

### make run

Launch the container as an instance named `grayskull` mapped on local port 80

### make stop

halt instance `grayskull`

### make clean

destroy the instance and image
