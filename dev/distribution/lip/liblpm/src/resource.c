#include "resource.h"

char *get_file_name(lpm_resource *res) 
{
	return res->file;
}

char *get_error_message(lpm_resource *res)
{
	return res->error_message;
}

int get_error_number(lpm_resource *res)
{
	return res->error_number;
}

