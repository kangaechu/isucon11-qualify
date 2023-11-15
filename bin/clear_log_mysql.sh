#!/bin/bash

set -ex
sudo truncate --size 0 /var/log/mysql/mysql-slow.log
sudo systemctl restart mysql.service
sudo chown mysql:adm /var/log/mysql/mysql-slow.log
