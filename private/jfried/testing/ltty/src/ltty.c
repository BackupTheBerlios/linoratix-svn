/**
 * This software is distributed under the terms of the gpl 2.0+
 *
 * homepage: http://www.linoratix.com/
 */

// fuer das tty
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/vt.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

// parameter
#include <getopt.h>


int main(int argc, char *argv[])
{
	int virtual_nr, virtual_fh, nologin;
	struct vt_stat vtstat;
	char terminal_name[100];
	pid_t child;
	char option;

	// uebergabe parameter auslesen
	while((option = getopt( argc, argv, "-e")) != EOF)
	{
		switch(tolower(option))
		{
			// direkt als root einloggen
			case 'e': nologin = 1; break; 
		}
	}

	if((virtual_fh = open("/dev/tty", O_RDWR, 0)) < 0)
	{
		printf("Fehler beim oeffnen von /dev/tty!\n");
	}

	if(ioctl(virtual_fh, VT_GETSTATE, &vtstat) < 0)
	{
		printf("tty ist keine virtuelle console!\n");
	}


	if(nologin == 1)
	{
		sprintf(terminal_name, argv[3]);
	} else
	{
		sprintf(terminal_name, argv[1]);
	}

	if(access(terminal_name, (W_OK|R_OK)) < 0)
	{
		printf("keine zugriffsrechte auf das tty!\n");
	}

	if((child = fork()) == 0)
	{
		ioctl(virtual_fh, VT_ACTIVATE, virtual_nr);
		ioctl(virtual_fh, VT_WAITACTIVE, virtual_nr);
		setsid();
		close(0);
		close(1);
		close(2);
		close(virtual_fh);
		virtual_fh = open(terminal_name, O_RDWR, 0); 
		dup(virtual_fh);
		dup(virtual_fh);
		if(nologin == 1)
		{
			execlp(argv[2], "bash", NULL);
		} else
		{
			execlp("/bin/login", "login", NULL);
		}
	}

	wait(NULL);

	ioctl(virtual_fh, VT_ACTIVATE, vtstat.v_active);
	ioctl(virtual_fh, VT_WAITACTIVE, vtstat.v_active);
	ioctl(virtual_fh, VT_DISALLOCATE, virtual_nr);

	exit(0);
}
