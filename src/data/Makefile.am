# Makefile.am for firstboot/src/data


fillupdir = /var/adm/fillup-templates/
fillup_DATA = sysconfig.firstboot

modconfigdir = $(prefix)/share/autoinstall/modules
modconfig_DATA = firstboot.desktop

schemafilesdir =  $(schemadir)/autoyast/rnc
schemafiles_DATA = $(wildcard *.rnc)

EXTRA_DIST = $(fillup_DATA) $(modconfig_DATA) $(schemafiles_DATA)

include $(top_srcdir)/Makefile.am.common
