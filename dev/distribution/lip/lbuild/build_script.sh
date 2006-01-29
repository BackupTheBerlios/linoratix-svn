#!/bin/bash

# exportierte / uebergebene parameter
#BUILD_BUILD_ENV=

# konfiguration einlesen
. ./build.conf
. ${INCLUDE_PATH}/functions.sh

export LBUILD_FILE=$1
export LBUILD_INFO=./parser.pl
export CURRENT_PATH=$(pwd)

mkdir -p ${BUILD_PATH}


####
# Meta Informationen
GROUP=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Meta/Group)
NAME=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Meta/Name)
VERSION=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Meta/Version)
LANGUAGES=-1
for lang in $(${LBUILD_INFO} -f ${LBUILD_FILE} -g Meta/Languages); do   # de en fr ...
	LANGUAGES=$(( ${LANGUAGES} + 1 ))
	LANGUAGE[${LANGUAGES}]=${lang}
done
HOMEPAGE=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Meta/Homepage)
LICENSE=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Meta/License)

####
# Maintainer Informationen
MAINTAINERS=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Maintainer/Maintainers)
MAINTAINERS=$(( ${MAINTAINERS} - 1 ))
BUGREPORTMAIL=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Maintainer/BugreportMail)
for ((maintainer=0; maintainer <= ${MAINTAINERS} ; maintainer++ )); do   # z.b.: 3
	NAME[${maintainer}]=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Maintainer/${maintainer}/Name)
	SURNAME[${maintainer}]=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Maintainer/${maintainer}/Surame)
	EMAIL[${maintainer}]=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Maintainer/${maintainer}/EMail)
	HOMEPAGE[${maintainer}]=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Maintainer/${maintainer}/Homepage)
	NICK[${maintainer}]=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Maintainer/${maintainer}/Nick)
done

####
# Beschreibung
DESCRIPTIONS=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Meta/Languages)   # de en fr ...
for description in ${DESCRIPTIONS}; do
	DESCRIPTION[${description}]=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Description/${description})
done

####
# Abhaengigkeiten
# die abhaengikeitenliste erzeugen

[ -d ${BUILD_PATH}/linoratix ] || mkdir -p ${BUILD_PATH}/linoratix/build
${LBUILD_INFO} -f ${LBUILD_FILE} -s Dependencies > ${BUILD_PATH}/linoratix/dependencies.inc.sh

# und einbinden
. ${BUILD_PATH}/linoratix/dependencies.inc.sh

if [ ! "${BUILD_BUILD_ENV}" ]; then
	# nur pruefen wenn nicht das build env gebaut wird
	echo
fi


####
# Bauabhaengigkeiten
${LBUILD_INFO} -f ${LBUILD_FILE} -s BuildDependencies > ${BUILD_PATH}/linoratix/build_dependencies.inc.sh
. ${BUILD_PATH}/linoratix/build_dependencies.inc.sh

if [ ! "${BUILD_BUILD_ENV}" ]; then
	# nur pruefen wenn nicht das build env gebaut wird
	echo
fi



####
# vorschlaege
${LBUILD_INFO} -f ${LBUILD_FILE} -s Recommendations > ${BUILD_PATH}/linoratix/recommendations.inc.sh
. ${BUILD_PATH}/linoratix/recommendations.inc.sh

if [ ! "${BUILD_BUILD_ENV}" ]; then
	# nur pruefen wenn nicht das build env gebaut wird
	echo
fi


####
# konfilkte
${LBUILD_INFO} -f ${LBUILD_FILE} -s Conflicts > ${BUILD_PATH}/linoratix/conflicts.inc.sh
. ${BUILD_PATH}/linoratix/conflicts.inc.sh

if [ ! "${BUILD_BUILD_ENV}" ]; then
	# nur pruefen wenn nicht das build env gebaut wird
	echo
fi

# das quellcode packet besorgen

for sourcefile in $(${LBUILD_INFO} -f ${LBUILD_FILE} -g SourceFiles/SourceFile); do
	server=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g DownloadServer/Main)
	cd ${BUILD_PATH}/linoratix/build
	wget -c --passive-ftp ${server}/${sourcefile}
	if [ "$?" != "0" ]; then
		get_from_mirror ${sourcefile}
	fi
	cd ${CURRENT_PATH}
done

#ANZAHL_PATCHES=$(${LBUILD_INFO} -f ${LBUILD_FILE} -g Patches/Patches)

#if [ "${ANZAHL_PATCHES}" ]; then
#	cd ${BUILD_PATH}
#	mkdir ../../patches
#	for ((patches=0; patches <= ${ANZAHL_PATCHES} ; patches++ )); do
#		echo "patching ... "
#		echo ${INSTALL_PATCH} "`${LBUILD_INFO} -f ${LBUILD_FILE} -g Patches/${patches}/PatchCommand}`" "`${LBUILD_INFO} -f ${LBUILD_FILE} -g Patches/${patches}/Patch}`"
#		sleep 10
#		${INSTALL_PATCH} "`${LBUILD_INFO} -f ${LBUILD_FILE} -g Patches/${patches}/PatchCommand}`" "`${LBUILD_INFO} -f ${LBUILD_FILE} -g Patches/${patches}/Patch}`"
#	done
#fi

cd ${CURRENT_PATH}
echo "#!/bin/bash" > ${BUILD_PATH}/l_configure.sh
echo "" >> ${BUILD_PATH}/l_configure.sh
${LBUILD_INFO} -f ${LBUILD_FILE} -g PrepareBuild >> ${BUILD_PATH}/l_configure.sh
chmod 755 ${BUILD_PATH}/l_configure.sh
cd ${BUILD_PATH}/linoratix/build
. ${BUILD_PATH}/l_configure.sh

cd ${CURRENT_PATH}
echo "#!/bin/bash" > ${BUILD_PATH}/l_make.sh
echo "" >> ${BUILD_PATH}/l_make.sh
${LBUILD_INFO} -f ${LBUILD_FILE} -g Build >> ${BUILD_PATH}/l_make.sh
chmod 755 ${BUILD_PATH}/l_make.sh
cd ${BUILD_PATH}/linoratix/build
. ${BUILD_PATH}/l_make.sh

cd ${CURRENT_PATH}
echo "#!/bin/bash" > ${BUILD_PATH}/l_preinstall.sh
echo "" >> ${BUILD_PATH}/l_preinstall.sh
${LBUILD_INFO} -f ${LBUILD_FILE} -g PreInstall >> ${BUILD_PATH}/l_preinstall.sh
chmod 755 ${BUILD_PATH}/l_preinstall.sh
cd ${BUILD_PATH}/linoratix/build
. ${BUILD_PATH}/l_preinstall.sh

cd ${CURRENT_PATH}
echo "#!/bin/bash" > ${BUILD_PATH}/l_install.sh
echo "" >> ${BUILD_PATH}/l_install.sh
${LBUILD_INFO} -f ${LBUILD_FILE} -g Install >> ${BUILD_PATH}/l_install.sh
chmod 755 ${BUILD_PATH}/l_install.sh
cd ${BUILD_PATH}/linoratix/build
. ${BUILD_PATH}/l_install.sh

cd ${CURRENT_PATH}
echo "#!/bin/bash" > ${BUILD_PATH}/l_postinstall.sh
echo "" >> ${BUILD_PATH}/l_postinstall.sh
${LBUILD_INFO} -f ${LBUILD_FILE} -g PostInstall >> ${BUILD_PATH}/l_postinstall.sh
chmod 755 ${BUILD_PATH}/l_postinstall.sh
cd ${BUILD_PATH}/linoratix/build
. ${BUILD_PATH}/l_postinstall.sh
