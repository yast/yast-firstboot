# Sources for firstboot

module_DATA = \
  modules/Firstboot.rb

client_DATA = \
  clients/firstboot_welcome.rb \
  clients/firstboot_keyboard.rb \
  clients/firstboot_write.rb \
  clients/firstboot.rb \
  clients/firstboot_ntp.rb \
  clients/firstboot_timezone.rb \
  clients/firstboot_ssh.rb \
  clients/firstboot_finish.rb \
  clients/firstboot_license.rb \
  clients/firstboot_desktop.rb \
  clients/firstboot_config.rb \
  clients/firstboot_language.rb \
  clients/firstboot_licenses.rb \
  clients/firstboot_language_keyboard.rb \
  clients/firstboot_license_novell.rb \
  clients/firstboot_network_write.rb \
  clients/firstboot_setup_dhcp.rb \
  clients/firstboot_auto.rb \
  clients/firstboot_hostname.rb \
  clients/firstboot_root.rb \
  clients/firstboot_user.rb \
  clients/firstboot_configuration_management.rb

yncludedir = @yncludedir@/firstboot
ynclude_DATA = \
  include/firstboot/routines.rb

scrconf_DATA = \
  scrconf/cfg_firstboot.scr

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/firstboot.rnc

fillup_DATA = \
  fillup/sysconfig.firstboot

ylibclientdir = "${yast2dir}/lib/y2firstboot/clients"
ylibclient_DATA = \
  lib/y2firstboot/clients/configuration_management.rb \
  lib/y2firstboot/clients/root.rb \
  lib/y2firstboot/clients/user.rb \
  lib/y2firstboot/clients/licenses.rb

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-firstboot-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-firstboot.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(schemafiles_DATA) $(fillup_DATA) $(ylibclient_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
