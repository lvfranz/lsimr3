#!/bin/bash

docker rmi -f builder
rm -rf artifacts
docker build -t builder .
docker run -i -v ${PWD}/artifacts:/artifacts builder sh << COMMANDS
cp lsimr3* /artifacts
COMMANDS
