all: sysguard

CC=gcc
CFLAGS=-g -Wall -Wpointer-arith -Wstrict-prototypes -fPIC -nostartfiles -shared -rdynamic -Wl,-soname,libSysGuard.so
LIBS=-ldl -lm

sysguard:
	$(CC) $(CFLAGS) libSysGuard.c -o libSysGuard.so $(LIBS)

clean:
	rm *.so

distclean: clean backups

backups:
	rm *~

install:
	install libSysGuard.so /lib
	install SysGuard.sh /sbin

