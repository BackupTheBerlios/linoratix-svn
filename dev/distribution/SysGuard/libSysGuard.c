/**
 * SysGuard
 *
 * Copyright (C) 2004 by Jan Gehring <jfried@linoratix.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/**
 * some parts are from the soapbox project
 */

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
	int _return = 1;
	char _action[PATH_MAX+1];
	
	_action[0] = '\0'; _action[PATH_MAX] = '\0';

	snprintf(_action, PATH_MAX, "%s unlink %s", getenv("SYSGUARD_ACTION"), rewrite(path, R_LINK));
	if(_action[0] == '/')
	{
		_return = system(_action);
		if(_return == 0)
		{
			return _real_unlink(path);
		}
		else
		{
			return -1;
		}
	}
	else
	{
		return -1;
	}
	
	return -1;
}

int remove(const char *path) 
{
	char _action[PATH_MAX+1];
	int _return = 1;
	
	_action[0] = '\0'; _action[PATH_MAX] = '\0';

	snprintf(_action, PATH_MAX, "%s remove %s", getenv("SYSGUARD_ACTION"), rewrite(path, R_LINK));


	if(_action[0] == '/')
	{
		_return = system(_action);
		if(_return == 0)
		{
			return _real_remove(path);
		}
		else
		{
			return -1;
		}
	}
	else
	{
		return -1;
	}
	
	return -1;
}

int rename(const char *oldpath, const char *newpath) 
{
	char _action[PATH_MAX+1];
	int _return = 1;
	
	_action[0] = '\0'; _action[PATH_MAX] = '\0';

	snprintf(_action, PATH_MAX, "%s rename %s %s", getenv("SYSGUARD_ACTION"), rewrite(oldpath, R_LINK), rewrite(newpath, R_FILE));


	if(_action[0] == '/')
	{
		_return = system(_action);
		if(_return == 0)
		{
			return _real_rename(oldpath, newpath);
		}
		else
		{
			return -1;
		}
	}
	else
	{
		return -1;
	}
	
	return -1;
}

int rmdir(const char *path) 
{
	char _action[PATH_MAX+1];
	int _return = 1;
	
	_action[0] = '\0'; _action[PATH_MAX] = '\0';

	snprintf(_action, PATH_MAX, "%s rmdir %s", getenv("SYSGUARD_ACTION"), rewrite(path, R_LINK));


	if(_action[0] == '/')
	{
		_return = system(_action);
		if(_return == 0)
		{
			return _real_rmdir(path);
		}
		else
		{
			return -1;
		}
	}
	else
	{
		return -1;
	}
	
	return -1;
}

