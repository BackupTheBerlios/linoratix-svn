#!/bin/bash

GREEN="\E[1;32m"
NORMAL="\E[0;39m"
RED="\E[1;31m"

echo -e "${GREEN}>>${NORMAL} Checking dependencies..."

function check_mysql()
{
	echo -n "Checking for mysql...		"
	if [ -f /usr/lib/libmysqlclient.so.14 ];
	then
		echo -e "[  ${GREEN}OK${NORMAL}  ]"
	else
		echo -e "[  ${RED}!!${NORMAL}  ]"
		echo -e "${RED}>>${NORMAL} install your mysql-dev package"
		exit 1
	fi
}


check_mysql

exit 0

