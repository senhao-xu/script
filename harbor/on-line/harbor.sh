#!/bin/bash
tar -zxvf harbor-online-installer-v2.4.1.tgz -C /usr/local/
cp harbor.yml /usr/local/harbor
sh /usr/local/harbor/install.sh