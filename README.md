<div align="center">
<img src="http://grsecurity.net/gfx/header_logo.png" alt="grsecurity logo"></img>
</div>

linux-grsec
===========

Arch Linux package for the Linux Kernel and modules with grsecurity/PaX patches.

* [AUR][0]
* [GitHub][1]
* [grsecurity project page][2]
* [Wikibook on grsecurity][3]


Kernel configuration
--------------------

Configure (with menuconfig) and exit afterwards:

    MENUCONFIG=1 makepkg

The configuration will be in `src/linux-3.*/.config`. In the PKGBUILDs build
function (line 91 ff.), the configuration interface is changeable.

To configure and build the kernel afterwards:

    MENUCONFIG=2 makepkg


grsecurity option configuration
-------------------------------

Many options are configurable by sysctl in `/etc/sysctl.d/05-grsecurity.conf`.
After `kernel.grsecurity.grsec_lock` is activated, there are no changes possible
anymore.

If you do not use KMS graphics, you have to disable
`kernel.grsecurity.disable_priv_io`.

There are six groups, which control grsecurity functions:

* tpe
* audit
* socket-deny-all
* socket-deny-client
* socket-deny-server 
* proc-trusted


[0]: https://aur.archlinux.org/packages/linux-grsec
[1]: https://github.com/nning/linux-grsec
[2]: https://grsecurity.net 
[3]: https://en.wikibooks.org/wiki/Grsecurity
