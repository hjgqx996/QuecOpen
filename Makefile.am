# Makefile.am - Automake script for data
#
ACLOCAL_AMFLAGS = -I m4

dirs :

#dirs = lib_src/at
dirs = lib_src/common_api
dirs += lib_src/peripheral

SUBDIRS = $(dirs)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = Ql-sdk-data.pc
EXTRA_DIST = $(pkgconfig_DATA)
