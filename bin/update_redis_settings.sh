#!/bin/bash

set -ex
sudo cp -pr infra/redis/* /etc/redis/
sudo chown -R redis:redis /etc/redis/
sudo systemctl restart redis-server.service --no-pager
sudo systemctl status redis-server.service --no-pager
