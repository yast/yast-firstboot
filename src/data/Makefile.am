# Makefile.am for firstboot/src/data


ydata_DATA =  firstboot_license.txt \
	      firstboot_welcome.txt \
	      firstboot_finish.txt


fillupdir = /var/adm/fillup-templates/
fillup_DATA = sysconfig.firstboot

	


EXTRA_DIST = $(ydata_DATA) $(fillup_DATA)

include $(top_srcdir)/Makefile.am.common
