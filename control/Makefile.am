# Makefile.am for installation/general

controldir = /etc/YaST2

control_DATA = \
	firstboot.xml 

# Note: The control.glade -> control.xml symlink is required to make xgettext
# auto-detect the type of this file (glade) so it will extract all
# <label>..</label> tags.

EXTRA_DIST =  $(control_DATA)

include $(top_srcdir)/Makefile.am.common
