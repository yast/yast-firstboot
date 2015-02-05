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
Version:        3.1.6
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
BuildRequires:	update-desktop-files docbook-xsl-stylesheets libxslt
BuildRequires:  yast2-devtools >= 3.1.10

# yast2/NeworkDevices -> yast2/NetworkInterfaces
Requires:	yast2 >= 2.16.23
Requires:	yast2-bootloader
# Language::SwitchToEnglishIfNeeded
Requires:	yast2-country >= 2.19.5
# new version of inst_license
Requires:	yast2-installation >= 2.19.0
# network autoconfiguration
Requires:	yast2-network >= 3.1.91

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

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
%dir %{yast_yncludedir}
%dir %{yast_yncludedir}/firstboot
%{yast_yncludedir}/firstboot/*.rb
%dir %{yast_moduledir}
%{yast_moduledir}/Firstboot.*
%dir %{yast_scrconfdir}
%{yast_scrconfdir}/*.scr
/var/adm/fillup-templates/sysconfig.firstboot
/usr/share/firstboot
%doc %{yast_docdir}
%doc COPYING
%dir /etc/YaST2/
/etc/YaST2/*.xml
%dir /usr/share/autoinstall
%dir /usr/share/autoinstall/modules
/usr/share/autoinstall/modules/firstboot.desktop
%dir %{yast_schemadir}
%dir %{yast_schemadir}/autoyast
%dir %{yast_schemadir}/autoyast/rnc
%{yast_schemadir}/autoyast/rnc/firstboot.rnc
