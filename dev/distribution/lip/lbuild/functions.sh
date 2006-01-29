#
# verschiedene funktionen die man so braucht
#

# farbdefinitionen

NORMAL="\033[0m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"

function lecho()
{
	echo -e ${GREEN} $*
}

function lerror()
{
	echo -e ${RED} $*
}

function lwarn()
{
	echo -e ${YELLOW} $*
}

function ldie()
{
	lerror $*
	exit 1
}

function get_from_mirror()
{
	cd ${CURRENT_PATH}
	file=$1
	for mirror in $(${LBUILD_INFO} -f ${LBUILD_FILE} -g DownloadServer/Mirror); do
		cd ${BUILD_PATH}/linoratix/build
		wget -c --passive-ftp ${mirror}/${file}
		if [ "$?" = 0 ]; then
			break
		fi
	done
}
