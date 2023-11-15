#!/bin/bash

set -ex
sudo cp -pr infra/mysql/* /etc/mysql/
sudo systemctl restart mysql.service --no-pager
sudo systemctl status mysql.service --no-pager
