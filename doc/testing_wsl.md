## Testing WSL Changes

This document serve as reminder how is the optimal way to test changes done for WSL firstboot as working with
windows server can be linux unfriendly and we would like to test without any mocking to get the best results.

### Creating Testing APPX

The easiest way is to use OBS. Find the target release for WSL image like `SUSE:SLE-15-SP6:Update:WSL`
and branch there `kiwi-images-wsl` that is responsible for creation of appx. In your branch create package
yast2-firstboot ( as it is usually inherited from target and does not live in WSL subproject ) and copy there
modified sources with rake tarball. It is also mandatory to link or branch package `wsl-appx` as it ensures
that certificate used for appx matches with the one used in kiwi.
Another important think is to ensure that certificate for home repo is valid and not outdated. To check it use
`osc signkey --sslcert home:...` and if it is invalid use `osc signkey --sslcert --create home:...`.

### Installing Modified APPX

Just follow instructions at https://en.opensuse.org/WSL/Manual_Installation
Appx installer reports quite useless error when there is any issue, so use help at https://en.opensuse.org/WSL/Debugging_Hints
