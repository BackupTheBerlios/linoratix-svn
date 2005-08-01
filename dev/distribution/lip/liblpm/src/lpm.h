/**
 * This software is distributed under the terms of the gpl
 */

#include "resource.h"

#ifndef LIBLPM_H
#define LIBLPM_H
#ifdef __cplusplus
extern "C" {
#endif

// verschiedene dateitypen die es so geben kann
typedef enum {
	REGULAR_FILE,
	DIRECTORY,
	SYMBOLIC_LINK,
	BLOCK_DEVICE,
	CHAR_DEVICE,
	FIFO_OR_SOCKET,
	SOCKET
} lpm_file_type;
	
// Datei
struct lpm_file {
	char *filename;
	unsigned int chmod;
	unsigned int uid;
	unsigned int gid;
	unsigned long size;
	char md5[32];
	char rmd160[40];
	unsigned int type;
	// Wenn symlink
	char *linked_with;
};

// abhaenigkeiten
typedef struct {
	char *package_name;
	char *package_version;
	char *version_modifier;
} lpm_dependency;

// der author
typedef struct {
	char *given_name;
	char *surname;
	char *email;
	char *homepage;
	char *nick;
} lpm_author;

typedef struct {
	lpm_author **persons;
	char *bugreport_email;
} lpm_maintainer;

// packet hauptstruktur
typedef struct {
	char *name;
	char *version;
	char *license;
	char *homepage;
	char *pre_install_script;
	char *post_install_script;
	char *configure_script;
	lpm_maintainer maintainer;
	lpm_author **authors;
	//struct lpm_file *files;
	lpm_dependency **dependencies;
} lpm_package;

// ein packet oeffnen
lpm_resource lpm_open(char*, int);

// liest packetinformationen aus
void package_info(lpm_package*);

// schreiben von packetinformationen
size_t lpm_write(lpm_resource*, lpm_package*);

// schliessen
int lpm_close(lpm_resource*);

// lesen aus datei
size_t lpm_read(lpm_resource*, lpm_package*);

#ifdef __cplusplus
}
#endif
#endif

