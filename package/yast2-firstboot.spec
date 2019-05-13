#
# spec file for package yast2-firstboot
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           yast2-firstboot
Version:        4.1.7
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0-only
BuildRequires:	update-desktop-files docbook-xsl-stylesheets libxslt
BuildRequires:  yast2-devtools >= 3.1.10

# yast2/NeworkDevices -> yast2/NetworkInterfaces
Requires:	yast2 >= 2.16.23
# Language::SwitchToEnglishIfNeeded
Requires:	yast2-country >= 2.19.5
# Rely on the YaST2-Firstboot.service for halting the system on failure
Requires:	yast2-installation >= 4.1.2
# network autoconfiguration
Requires:	yast2-network >= 3.1.91

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0
Requires:       yast2-configuration-management >= 4.1.3

Summary:	YaST2 - Initial System Configuration
PreReq:         %fillup_prereq

%description
The YaST firstboot utility runs after installation is completed.  It
guides the user through a series of steps that allows for easier
configuration of the machine.

YaST firstboot does not run by default and has	to be configured to run
by the user or the system administrator. It is useful for image
deployments where the system in the image is completely configured,
however some last steps like root password and user logins have to be
created to personalize the system.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install

# Remove the license from the /usr/share/doc/packages directory,
# it is also included in the /usr/share/licenses directory by using
# the %license tag.
rm -f $RPM_BUILD_ROOT/%{yast_docdir}/COPYING

mkdir -p $RPM_BUILD_ROOT/usr/share/firstboot/scripts


%post
%{fillup_only -n firstboot}

%files
%defattr(-,root,root)
%dir %{yast_ystartupdir}/startup
%dir %{yast_ystartupdir}/startup/Firstboot-Stage
%{yast_ystartupdir}/startup/Firstboot-Stage/*
%{yast_ystartupdir}/startup/YaST2.Firstboot
%{yast_clientdir}/firstboot_*.rb
%{yast_clientdir}/firstboot.rb
%dir %{yast_libdir}
%dir %{yast_libdir}/y2firstboot
%dir %{yast_libdir}/y2firstboot/clients
%{yast_libdir}/y2firstboot/clients/*.rb
%dir %{yast_yncludedir}
%dir %{yast_yncludedir}/firstboot
%{yast_yncludedir}/firstboot/*.rb
%dir %{yast_moduledir}
%{yast_moduledir}/Firstboot.*
%dir %{yast_scrconfdir}
%{yast_scrconfdir}/*.scr
%{_fillupdir}/sysconfig.firstboot
/usr/share/firstboot
%doc %{yast_docdir}
%license COPYING
%dir /etc/YaST2/
/etc/YaST2/*.xml
%dir /usr/share/autoinstall
%dir /usr/share/autoinstall/modules
/usr/share/autoinstall/modules/firstboot.desktop
%dir %{yast_schemadir}
%dir %{yast_schemadir}/autoyast
%dir %{yast_schemadir}/autoyast/rnc
%{yast_schemadir}/autoyast/rnc/firstboot.rnc
%{yast_icondir}
