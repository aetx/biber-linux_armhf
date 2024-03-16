#!/bin/bash

docker build \
	-f Dockerfile.debian \
	--target test \
	-t aetx/biber \
	--build-arg biberversion=2.19 \
	.

docker create --name dummy_copy aetx/biber
docker cp dummy_copy:/biber-linux_armv7 .
docker rm -f dummy_copy
