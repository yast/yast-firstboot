# Makefile.am for firstboot/src

yncludedir = @yncludedir@/firstboot
SUBDIRS = data control

client_DATA =			\
	firstboot_welcome.ycp	\
	firstboot_license.ycp	\
	firstboot_finish.ycp	\
	firstboot_write.ycp	\
	firstboot_language.ycp	\
	firstboot_timezone.ycp	\
	firstboot.ycp

ynclude_DATA =			\
	routines.ycp

module_DATA =			\
	Firstboot.ycp

EXTRA_DIST = $(client_DATA) $(module_DATA)  $(ynclude_DATA)

include $(top_srcdir)/Makefile.am.common
