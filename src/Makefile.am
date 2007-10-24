# Makefile.am for firstboot/src

yncludedir = @yncludedir@/firstboot
SUBDIRS = data control

client_DATA =			\
	firstboot_write.ycp	\
	firstboot_desktop.ycp	\
	firstboot_language.ycp	\
	firstboot_timezone.ycp	\
	firstboot_license.ycp	\
	firstboot_welcome.ycp	\
	firstboot_ssh.ycp	\
	firstboot_keyboard.ycp	\
	firstboot.ycp		\
	firstboot_license_novell.ycp	\
	firstboot_network_write.ycp	\
	firstboot_bootloader_reconfigure.ycp

ynclude_DATA =			\
	routines.ycp

module_DATA =			\
	Firstboot.ycp	

EXTRA_DIST = $(client_DATA) $(module_DATA)  $(ynclude_DATA)

include $(top_srcdir)/Makefile.am.common
