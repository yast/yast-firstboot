## Testing the WSL Changes

This document describes how to test the firstboot workflow in Microsoft Windows
using the WSL (Windows Subsystem for Linux) support. You can test the changes in
a Linux machine but ideally we would like to test them without any mocking to
get the best results.

If you are not familiar with WSL then check the [WSL
documentation](https://learn.microsoft.com/en-us/windows/wsl/).

### WSL Installation

There a two versions of WSL, WSL1 and WSL2. The WSL2 is newer and is the default
installed version. In general it should work better and should be preferred.

Unfortunately the WSL2 does not work in some virtualization environments. If you
run your Windows instance in a VirtualBox VM then you will get an error. In that
case you should switch to WSL1.

See more details about the WSL versions and their differences in the
[documentation](
https://learn.microsoft.com/en-us/windows/wsl/compare-versions#comparing-wsl-1-and-wsl-2).

#### Hints

In Windows 10 install the [Microsoft
Terminal](https://apps.microsoft.com/detail/9n0dx20hk701) application. In
Windows 11 it is installed by default.

It has several nice features like tabs, full screen mode or font
resizing. It feels more close to the usual Linux terminals, it is much better
than a plain PowerShell window...

#### Installing WSL1

If you want to explicitly use WSL1 then first run these commands in Terminal or
PowerShell:

- Start the `wsl --install --no-distribution` command
- Reboot the system
- Windows 11 by default do not install WSL1, run `OptionalFeatures.exe` and
  select "Windows Subsystem for Linux", then reboot. This is not needed in
  Windows 10.
- Run `wsl --set-default-version 1`

Then continue in the WSL2 installation section below.

#### Installing WSL2

The WSL2 is the default version, if you want to install WSL1 then first run the
commands in the previous section.

Install the official SLE15-SP6 image:

    wsl --install -d SUSE-Linux-Enterprise-15-SP6

This will download and install the SLE15-SP6 image and then start the WSL
machine. At the first run it starts the firstboot workflow.

If you want to start the machine later then either find it in the start menu or
just run `wsl` command in Terminal or select the SLE15-SP6 Terminal profile.

### Testing Firstboot

If you install the SUSE-Linux-Enterprise-15-SP6 then it runs automatically the
firstboot workflow at the first start.

If you want to test your modified package then abort it at the very first
"Welcome" screen and install an updated package using `rpm` or `zypper`.

To start the firstboot workflow again then just run:

    /usr/lib/YaST2/startup/YaST2.Firstboot

### Creating a Testing APPX

In most cases you can simply update the yast2-firstboot RPM package (see the
previous section). But if you really need to build your own WSL image then it is
possible.

The WSL uses the standard APPX format which is used for distributing the normal
Windows applications. An APPX file is basically a ZIP archive so you can easily
inspect it when needed. A WSL APPX image contains a tarball with complete Linux
root tree.

The easiest way to build your own WSL image is to use OBS. Find the target
release for WSL image like `SUSE:SLE-15-SP6:Update:WSL` and branch there
`kiwi-images-wsl` that is responsible for creation of APPX.

In your branch create package yast2-firstboot (as it is usually inherited from
target and does not live in WSL subproject) and copy there modified sources
generated with `rake tarball`.

It is also mandatory to link or branch package `wsl-appx` as it ensures that
the certificate used for the APPX image matches with the one used in kiwi.

Another important thing is to ensure that the certificate for your home
repository is valid and not outdated. Check it with the `osc signkey --sslcert
home:...` command and if it is invalid then use `osc signkey --sslcert --create
home:...` to create a new certificate.

### Installing Modified APPX

Just follow [these
instructions](https://en.opensuse.org/WSL/Manual_Installation).

If the APPX installer fails then check these [debugging
hints](https://en.opensuse.org/WSL/Debugging_Hints).
