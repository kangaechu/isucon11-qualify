#!/bin/bash

set -ex
sudo cp -pr infra/nginx/* /etc/nginx/
sudo systemctl restart nginx.service --no-pager
sudo systemctl status nginx.service --no-pager
