#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <dlfcn.h>

#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <utime.h>
#include <fcntl.h>
#include <limits.h>

#include <time.h>

static int (*_real_remove)	(const char *);
static int (*_real_rename)	(const char *, const char *);
static int (*_real_rmdir)	(const char *);
static int (*_real_unlink)	(const char *);

enum { R_FILE, R_LINK };

static char *dirname(const char *path) {
	char *ptr;
	char safe[PATH_MAX+1];
	safe[0]='\0'; safe[PATH_MAX]='\0'; // Terminate string for safety :)

	if (strrchr(path, '/')==NULL) {
		getcwd(safe, PATH_MAX);
	} else {
		snprintf(safe, PATH_MAX, "%s", path);
		ptr=strrchr(safe, '/');
		*ptr='\0';
	}
	return strndup(safe, strlen(safe));
}


// Rewrite relative path to absolute.
static char *rewrite(const char *path, const int flag) {
	char *linkdir, *out;
	struct stat *buf;
	char temp[PATH_MAX+1], safe[PATH_MAX+1];

	temp[0]='\0'; temp[PATH_MAX]='\0'; // Terminate string for safety :)
	safe[0]='\0'; safe[PATH_MAX]='\0'; // Terminate string for safety :)

	// To make sure path is not empty and defined. Return empty string
	if (!path || *path=='\0')
		return strndup(safe, 0);

	// Check if file exists
	buf=malloc(sizeof(struct stat));
	if (lstat(path, buf)==0) {
		int type=(buf->st_mode & 0170000);

		// If it is a symlink and if asked (R_LINK), we should make its dirname absolute
		// (not the symlink) and add its basename
		if ((type==S_IFLNK) && (flag==R_LINK)) {
			linkdir=rewrite(dirname(path), R_LINK);
			snprintf(safe, PATH_MAX, "%s/%s", linkdir, basename(path));
			free(linkdir);
		} else {
			realpath(path, safe);
		}
	} else {
		realpath(path, safe);	// TODO: Problem with non-existing files !!
	}
	free(buf);

	out=strndup(safe, strlen(safe));

	return out;
}

void _init(int argc, char *argv[]) 
{
	setvbuf(stdout, (char *) NULL, _IONBF, 0);
	setvbuf(stderr, (char *) NULL, _IONBF, 0);

	_real_remove=dlsym(RTLD_NEXT, "remove"); 
	_real_rename=dlsym(RTLD_NEXT, "rename"); 
	_real_rmdir=dlsym(RTLD_NEXT, "rmdir"); 
	_real_unlink=dlsym(RTLD_NEXT, "unlink"); 
}


int unlink(const char *path) 
{
	int _return = 0;
	char _action[401];
	_action[0] = '\0'; _action[400] = '\0';

	snprintf(_action, 400, "%s unlink %s", getenv("SYSGUARD_ACTION"), rewrite(path, R_LINK));
	if(_action[0] == '/')
	{
		_return = system(_action);
		if(_return == 0)
		{
			return _real_unlink(path);
		}
		else
		{
			free(_action);
			return -1;
		}
	}
	else
	{
		return -1;
	}
}
