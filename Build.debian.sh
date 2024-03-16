#!/bin/bash

# $1: biber version

docker build \
	-f Dockerfile.debian \
	--target test \
	-t aetx/biber \
	--build-arg biberversion=$1 \
	.

docker create --name dummy_copy aetx/biber
docker cp dummy_copy:/biber-linux_armv7 .
docker rm -f dummy_copy
