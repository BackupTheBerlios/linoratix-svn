# set the include path found by configure
INCLUDES = $(all_includes)

CXXFLAGS= -O2 -fexceptions -fno-check-new

### The shared library ###
lib_LTLIBRARIES = libpartedpp.la
libpartedpp_la_LIBADD = -lparted
libpartedpp_la_LDFLAGS = -version-info 0:1:0 $(all_libraries)
libpartedpp_la_SOURCES = \
    alignment.cc      \
    constraint.cc     \
    device.cc         \
    disk.cc           \
    disktype.cc       \
    exception.cc      \
    filesystem.cc     \
    filesystemtype.cc \
    geometry.cc       \
    partition.cc      \
    timerhandler.cc   \
    timer.cc

### The static library ###
#noinst_LIBRARIES = libpartedpp.a
#libpartedpp_a_LIBADD = -lparted -ldl
#libpartedpp_a_METASOURCES = AUTO
#libpartedpp_a_SOURCES = \

### The Includes ###
libpartedppincludedir = $(includedir)/partedpp
libpartedppinclude_HEADERS = \
    alignment.h       \
    constraint.h      \
    device.h          \
    disk.h            \
    disktype.h        \
    exception.h       \
    filesystem.h      \
    filesystemtype.h  \
    geometry.h        \
    partition.h       \
    timerhandler.h    \
    timer.h           \
    partedpp.h

EXTRA_DIST = \
      alignment.cc      \
      constraint.cc     \
      device.cc         \
      disk.cc           \
      disktype.cc       \
      exception.cc      \
      filesystem.cc     \
      filesystemtype.cc \
      geometry.cc       \
      partition.cc      \
      timerhandler.cc   \
      timer.cc          \
      alignment.h       \
      constraint.h      \
      device.h          \
      disk.h            \
      disktype.h        \
      exception.h       \
      filesystem.h      \
      filesystemtype.h  \
      geometry.h        \
      partition.h       \
      timerhandler.h    \
      timer.h           \
      partedpp.h
