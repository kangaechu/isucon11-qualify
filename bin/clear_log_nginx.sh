#!/bin/bash

set -ex
sudo truncate --size 0 /var/log/nginx/access.log
sudo systemctl restart nginx.service
