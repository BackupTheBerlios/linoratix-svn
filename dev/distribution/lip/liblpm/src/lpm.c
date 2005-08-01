#include "lpm.h"
#include <stdlib.h>
#include <stdio.h>

/**
 * Oeffnet ein Packet
 *
 * @param char* file Dateiname
 * @param int mode oeffnen modus
 * @return lpm_resource Resourcehandle
 */
lpm_resource lpm_open(char *file, int mode)
{
	lpm_resource res;
	res.file = malloc(strlen(file)+1);
	strcpy(res.file, file);

	switch(mode)
	{
		case RES_OPEN_R:
			if((res.fh = fopen(file, "rb")) == NULL)
			{ // Fehler beim oeffnen
				res.error_number = RES_ERROR_OPEN_READ;
			}
			break;
		case RES_OPEN_W:
			if((res.fh = fopen(file, "wb")) == NULL)
			{ // Fehler beim oeffnen
				res.error_number = RES_ERROR_OPEN_WRITE;
			}
			break;
		default:
			res.error_number = RES_ERROR_INVALID_MODE;
			break;
	}
	
	return res;
}

/**
 * Schliessen einer Datei
 *
 * @param lpm_resource res resource handle
 * @return int 0 oder EOF (bei fehler)
 */
int lpm_close(lpm_resource *res)
{
	return fclose((*res).fh);
}

/**
 * Schreibt packetinformationen
 *
 * @param lpm_resource res resource handle
 * @param lpm_package pkg die packetinformationen
 * @return int geschriebene bytes
 */
size_t lpm_write(lpm_resource *res, lpm_package *pkg)
{
	return fwrite(pkg, sizeof(lpm_package), 1, (*res).fh);
}

/**
 * aus packetdatei lesen
 *
 * @param lpm_resource res resource handle
 * @param lpm_package pkg packet
 * @return size_t gelesene daten
 */
size_t lpm_read(lpm_resource *res, lpm_package *pkg)
{
	return fread(pkg, sizeof(lpm_package), 1, (*res).fh);
}


/**
 * Liest packetinformationen aus
 *
 * @param lpm_package pkg eine leere lpm_package struktur
 * @param lpm_resource res ein resource handle
 */
void package_info(lpm_package *pkg)
{
	// name
/*	pkg->name = malloc(9);
	strcpy(pkg->name, "libglibc");

	// author
	pkg->author->given_name = malloc(4);
	strcpy(pkg->author->given_name, "jan");

	//strcpy(pkg.author.give_name, "jan"); */
}

