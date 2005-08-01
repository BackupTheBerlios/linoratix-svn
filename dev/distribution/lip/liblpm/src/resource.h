/**
 * This software is distributed under the terms of the gpl
 */

#include <stdio.h>

#ifndef RESOURCE_H
#define RESOURCE_H
#ifdef __cplusplus
extern "C" {
#endif

// resource modus
typedef enum {
	RES_OPEN_R,  // Lesen
	RES_OPEN_W   // Schreiben
} lpm_res_mode;

typedef enum {
	RES_ERROR_INVALID_MODE,
	RES_ERROR_OPEN_WRITE,
	RES_ERROR_OPEN_READ
} lpm_res_error;

// lpm resource handle
typedef struct {
	char *file;
	int mode;
	FILE *fh;
	int error_number;
	char *error_message;
} lpm_resource;

// dateinamen aus einer resource nehmen
char *get_file_name(lpm_resource*);

// Fehlermeldung holen
char *get_error_message(lpm_resource*);

// Fehlernummer holen
int get_error_number(lpm_resource*);

#ifdef __cplusplus
}
#endif
#endif

