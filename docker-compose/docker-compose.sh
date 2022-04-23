#!/bin/bash
CRTDIR=$(pwd)
mv $CRTDIR/docker-compose /usr/local/bin
chmod +x /usr/local/bin/docker-compose
docker-compose --version