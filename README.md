YaST - System Configuration at First-Boot
=========================================

[![Workflow Status](https://github.com/yast/yast-firstboot/workflows/CI/badge.svg?branch=master)](
https://github.com/yast/yast-firstboot/actions?query=branch%3Amaster)
[![Jenkins Status](https://ci.opensuse.org/buildStatus/icon?job=yast-yast-firstboot-master)](
https://ci.opensuse.org/view/Yast/job/yast-yast-firstboot-master/)
[![Coverage Status](https://coveralls.io/repos/github/yast/yast-firstboot/badge.svg?branch=master)](
https://coveralls.io/github/yast/yast-firstboot?branch=master)


Description
===========

This is a special YaST module that allows users to configure pre-installed
systems to match their needs, e.g., language, network settings, root password,
etc.

The workflow is defined in a
[control file](control/firstboot.xml),
which uses the same format as the
[Installer control file](https://github.com/yast/yast-installation/blob/master/doc/control-file.md).
The default control file can be found in
[control directory](control).

More subject-specific pieces of information can be found in the [doc](doc)
directory.

Development
===========

This module is developed as part of YaST. See the
[development documentation](http://yastgithubio.readthedocs.org/en/latest/development/).

Getting the Sources
===================

To get the source code, clone the GitHub repository:

    $ git clone https://github.com/yast/yast-firstboot.git

If you want to contribute into the project you can
[fork](https://help.github.com/articles/fork-a-repo/) the repository and clone your fork.

Testing Environment
===================

##To test your first-boot workflow

1. Install yast2-firstboot package from media or directly from sources at GitHub
2. Copy your firstboot control file to /etc/YaST2/firstboot.xml
3. Enable first boot at startup `sudo systemctl enable YaST2-Firstboot.service`
4. Make sure this file exists `sudo touch /var/lib/YaST2/reconfig_system`
5. Reboot the system
6. While booting again, YaST2-Firstboot service checks for existence of
   /var/lib/YaST2/reconfig_system and starts the configuration workflow

Contact
=======

If you have any question, feel free to ask at the [development mailing
list](http://lists.opensuse.org/yast-devel/) or at the
[#yast](https://web.libera.chat/#yast) IRC channel on libera.chat.
