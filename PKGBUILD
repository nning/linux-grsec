# Original kernel maintainers:
#   Tobias Powalowski <tpowa@archlinux.org>
#   Thomas Baechler <thomas@archlinux.org>
# Contributors:
#   henning mueller <henning@orgizm.net>

pkgname=linux-grsec
true && pkgname=(linux-grsec linux-grsec-headers)
_kernelname=${pkgname#linux}
_basekernel=3.5
_grsecver=2.9.1
_timestamp=201208271906
pkgver=${_basekernel}.3
pkgrel=2
arch=(i686 x86_64)
url="http://www.kernel.org/"
license=(GPL2)
options=(!strip)

_menuconfig=0
[ ! -z $MENUCONFIG ] && _menuconfig=1

source=(
  ftp://ftp.halifax.rwth-aachen.de/pub/linux/kernel/v3.x/linux-$_basekernel.tar.xz
  ftp://ftp.halifax.rwth-aachen.de/pub/linux/kernel/v3.x/patch-$pkgver.xz
  http://grsecurity.net/test/grsecurity-$_grsecver-$pkgver-$_timestamp.patch
  config.i686
  config.x86_64
  $pkgname.install
  $pkgname.preset
  change-default-console-loglevel.patch
  alsa-powersave-3.5.x.patch
  watchdog-3.5.x.patch
  i915-i2c-crash-3.5.x.patch
)
sha256sums=(
  b985ce383f0cfd940d988d4c99a84899028327aca8c29b420678241f26fdb342
  79a9464a0a3fc242794394e0593634fa44b696a61e3364a42d1e9d13e9f2750d
  00b058d298698f58eb4c52ad714afab67785d9d64f0ad2d552e7bc2398e6b818
  31cc4522859bd7559d6f1ad06443296dd803b8fe32ced764a7cd4eeba3da6fe6
  fccc258eaad41f46727042729cb3308b327b6d111417ed1b376e5d22c2c19b0f
  57ec92e05ae4ee11f7e87599b921c82198fee51c05f1349e29c57cfcbb2638a7
  ca7e718375b3790888756cc0a64a7500cd57dddb9bf7e10a0df22c860d91f74d
  b9d79ca33b0b51ff4f6976b7cd6dbb0b624ebf4fbf440222217f8ffc50445de4
  bab85b2bb775d9db4585336707cd619fe1cfd8c5959368a5642a0f9c13acf0b8
  3b285aa62940908ef9dd2a72f81c28fd2c8102367188ef349509ff0f7d7f4fa8
  bc9be7e4e5bc81aa30754a96f6a94c2e6eb6a147165a2ac50972c1fd59ef9964
)

build() {
  cd "$srcdir/linux-$_basekernel"

  # add upstream patch
  patch -p1 -i "$srcdir/patch-$pkgver"

  # set DEFAULT_CONSOLE_LOGLEVEL to 4 (same value as the 'quiet' kernel param)
  # remove this when a Kconfig knob is made available by upstream
  # (relevant patch sent upstream: https://lkml.org/lkml/2011/7/26/227)
  patch -Np1 -i "${srcdir}/change-default-console-loglevel.patch"

  # fix alsa powersave bug, probably fixed in 3.5.4
  # https://bugs.archlinux.org/task/31255
  patch -Np1 -i  "${srcdir}/alsa-powersave-3.5.x.patch"

  # fix broken watchdog
  # https://bugzilla.kernel.org/show_bug.cgi?id=44991
  patch -Np1 -i "${srcdir}/watchdog-3.5.x.patch"

  # fix i915 i2c crash
  # https://bugzilla.kernel.org/show_bug.cgi?id=46381
  patch -Np1 -i "${srcdir}/i915-i2c-crash-3.5.x.patch"

  # Add grsecurity patches
  patch -Np1 -i $srcdir/grsecurity-$_grsecver-$pkgver-$_timestamp.patch
  rm localversion-grsec

  cat "${srcdir}/config.${CARCH}" > ./.config

  if [ "${_kernelname}" != "" ]; then
    sed -i "s|CONFIG_LOCALVERSION=.*|CONFIG_LOCALVERSION=\"${_kernelname}\"|g" ./.config
  fi

  # set extraversion to pkgrel
  sed -ri "s|^(EXTRAVERSION =).*|\1 -${pkgrel}|" Makefile

  # don't run depmod on 'make install'. We'll do this ourselves in packaging
  sed -i '2iexit 0' scripts/depmod.sh

  # get kernel version
  [ "$_menuconfig" = "0" ] && {
    make prepare
  }

  # load configuration
  # Configure the kernel. Replace the line below with one of your choice.
  [ "$_menuconfig" = "1" ] && {
    make menuconfig # CLI menu for configuration
    #make nconfig # new CLI menu for configuration
    #make xconfig # X-based configuration
    #make oldconfig # using old config from previous kernel version
    # ... or manually edit .config
  }

  ####################
  # stop here
  # this is useful to configure the kernel
  [ "$_menuconfig" = "1" ] && {
    msg "Stopping build"
    return 1
  }
  ####################

  yes "" | make config

  # build!
  make ${MAKEFLAGS} bzImage modules
}

package_linux-grsec() {
  pkgdesc="The Linux Kernel and modules with PaX patches"
  groups=('base')
  depends=('linux-pax-flags' 'coreutils' 'linux-firmware' 'kmod' 'mkinitcpio>=0.7')
  optdepends=('crda: to set the correct wireless channels of your country')
  provides=('kernel26-grsec')
  conflicts=('kernel26-grsec')
  replaces=('kernel26-grsec')
  backup=("etc/mkinitcpio.d/${pkgname}.preset")
  install=${pkgname}.install

  cd "$srcdir/linux-$_basekernel"

  KARCH=x86

  # get kernel version
  _kernver="$(make kernelrelease)"

  mkdir -p "${pkgdir}"/{lib/modules,lib/firmware,boot}
  make INSTALL_MOD_PATH="${pkgdir}" modules_install
  cp arch/$KARCH/boot/bzImage "${pkgdir}/boot/vmlinuz-${pkgname}"

  # add vmlinux and gcc plugins
  install -Dm644 vmlinux "$pkgdir/usr/src/linux-$_kernver/vmlinux"
  mkdir "$pkgdir/usr/src/linux-$_kernver/tools/gcc/"
  install -m644 tools/gcc/*.so "$pkgdir/usr/src/linux-$_kernver/tools/gcc/"

  # install fallback mkinitcpio.conf file and preset file for kernel
  install -D -m644 "${srcdir}/${pkgname}.preset" "${pkgdir}/etc/mkinitcpio.d/${pkgname}.preset"

  # set correct depmod command for install
  sed \
    -e  "s/KERNEL_NAME=.*/KERNEL_NAME=${_kernelname}/g" \
    -e  "s/KERNEL_VERSION=.*/KERNEL_VERSION=${_kernver}/g" \
    -i "${startdir}/${pkgname}.install"
  sed \
    -e "s|ALL_kver=.*|ALL_kver=\"/boot/vmlinuz-${pkgname}\"|g" \
    -e "s|default_image=.*|default_image=\"/boot/initramfs-${pkgname}.img\"|g" \
    -e "s|fallback_image=.*|fallback_image=\"/boot/initramfs-${pkgname}-fallback.img\"|g" \
    -i "${pkgdir}/etc/mkinitcpio.d/${pkgname}.preset"

  # remove build and source links
  rm -f "${pkgdir}"/lib/modules/${_kernver}/{source,build}
  # remove the firmware
  rm -rf "${pkgdir}/lib/firmware"
  # gzip -9 all modules to save 100MB of space
  find "${pkgdir}" -name '*.ko' -exec gzip -9 {} \;
  # make room for external modules
  ln -s "../extramodules-${_basekernel}${_kernelname:--ARCH}" "${pkgdir}/lib/modules/${_kernver}/extramodules"
  # add real version for building modules and running depmod from post_install/upgrade
  mkdir -p "${pkgdir}/lib/modules/extramodules-${_basekernel}${_kernelname:--ARCH}"
  echo "${_kernver}" > "${pkgdir}/lib/modules/extramodules-${_basekernel}${_kernelname:--ARCH}/version"

  # move module tree /lib -> /usr/lib
  mv "$pkgdir/lib" "$pkgdir/usr"

  # Now we call depmod...
  depmod -b "$pkgdir" -F System.map "$_kernver"
}

package_linux-grsec-headers() {
  true && pkgdesc="Header files and scripts for building modules for linux kernel with PaX patches"
  provides=('kernel26-grsec-headers')
  conflicts=('kernel26-grsec-headers')
  replaces=('kernel26-grsec-headers')

  install -dm755 "${pkgdir}/usr/lib/modules/${_kernver}"

  cd "${pkgdir}/usr/lib/modules/${_kernver}"
  ln -sf ../../../src/linux-${_kernver} build

  cd "$srcdir/linux-$_basekernel"
  install -D -m644 Makefile \
    "${pkgdir}/usr/src/linux-${_kernver}/Makefile"
  install -D -m644 kernel/Makefile \
    "${pkgdir}/usr/src/linux-${_kernver}/kernel/Makefile"
  install -D -m644 .config \
    "${pkgdir}/usr/src/linux-${_kernver}/.config"

  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/include"

  for i in acpi asm-generic config crypto drm generated linux math-emu \
    media mtd net pcmcia scsi sound trace video xen; do
    cp -a include/${i} "${pkgdir}/usr/src/linux-${_kernver}/include/"
  done

  # copy arch includes for external modules
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/arch/x86"
  cp -a arch/x86/include "${pkgdir}/usr/src/linux-${_kernver}/arch/x86/"

  # copy files necessary for later builds, like nvidia and vmware
  cp Module.symvers "${pkgdir}/usr/src/linux-${_kernver}"
  cp -a scripts "${pkgdir}/usr/src/linux-${_kernver}"

  # fix permissions on scripts dir
  chmod og-w -R "${pkgdir}/usr/src/linux-${_kernver}/scripts"
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/.tmp_versions"

  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/arch/${KARCH}/kernel"

  cp arch/${KARCH}/Makefile "${pkgdir}/usr/src/linux-${_kernver}/arch/${KARCH}/"

  if [ "${CARCH}" = "i686" ]; then
    cp arch/${KARCH}/Makefile_32.cpu "${pkgdir}/usr/src/linux-${_kernver}/arch/${KARCH}/"
  fi

  cp arch/${KARCH}/kernel/asm-offsets.s "${pkgdir}/usr/src/linux-${_kernver}/arch/${KARCH}/kernel/"

  # add headers for lirc package
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/video"

  cp drivers/media/video/*.h  "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/video/"

  for i in bt8xx cpia2 cx25840 cx88 em28xx pwc saa7134 sn9c102; do
    mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/video/${i}"
    cp -a drivers/media/video/${i}/*.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/video/${i}"
  done

  # add docbook makefile
  install -D -m644 Documentation/DocBook/Makefile \
    "${pkgdir}/usr/src/linux-${_kernver}/Documentation/DocBook/Makefile"

  # add dm headers
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/md"
  cp drivers/md/*.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/md"

  # add inotify.h
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/include/linux"
  cp include/linux/inotify.h "${pkgdir}/usr/src/linux-${_kernver}/include/linux/"

  # add wireless headers
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/net/mac80211/"
  cp net/mac80211/*.h "${pkgdir}/usr/src/linux-${_kernver}/net/mac80211/"

  # add dvb headers for external modules
  # in reference to:
  # http://bugs.archlinux.org/task/9912
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/dvb-core"
  cp drivers/media/dvb/dvb-core/*.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/dvb-core/"
  # and...
  # http://bugs.archlinux.org/task/11194
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/include/config/dvb/"
  cp include/config/dvb/*.h "${pkgdir}/usr/src/linux-${_kernver}/include/config/dvb/"

  # add dvb headers for http://mcentral.de/hg/~mrec/em28xx-new
  # in reference to:
  # http://bugs.archlinux.org/task/13146
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/frontends/"
  cp drivers/media/dvb/frontends/lgdt330x.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/frontends/"
  cp drivers/media/video/msp3400-driver.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/frontends/"

  # add dvb headers
  # in reference to:
  # http://bugs.archlinux.org/task/20402
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/dvb-usb"
  cp drivers/media/dvb/dvb-usb/*.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/dvb-usb/"
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/frontends"
  cp drivers/media/dvb/frontends/*.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/dvb/frontends/"
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/common/tuners"
  cp drivers/media/common/tuners/*.h "${pkgdir}/usr/src/linux-${_kernver}/drivers/media/common/tuners/"

  # add xfs and shmem for aufs building
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/fs/xfs"
  mkdir -p "${pkgdir}/usr/src/linux-${_kernver}/mm"
  cp fs/xfs/xfs_sb.h "${pkgdir}/usr/src/linux-${_kernver}/fs/xfs/xfs_sb.h"

  # copy in Kconfig files
  for i in `find . -name "Kconfig*"`; do
    mkdir -p "${pkgdir}"/usr/src/linux-${_kernver}/`echo ${i} | sed 's|/Kconfig.*||'`
    cp ${i} "${pkgdir}/usr/src/linux-${_kernver}/${i}"
  done

  chown -R root.root "${pkgdir}/usr/src/linux-${_kernver}"
  find "${pkgdir}/usr/src/linux-${_kernver}" -type d -exec chmod 755 {} \;

  # strip scripts directory
  find "${pkgdir}/usr/src/linux-${_kernver}/scripts" -type f -perm -u+w 2>/dev/null | while read binary ; do
    case "$(file -bi "${binary}")" in
      *application/x-sharedlib*) # Libraries (.so)
        /usr/bin/strip ${STRIP_SHARED} "${binary}";;
      *application/x-archive*) # Libraries (.a)
        /usr/bin/strip ${STRIP_STATIC} "${binary}";;
      *application/x-executable*) # Binaries
        /usr/bin/strip ${STRIP_BINARIES} "${binary}";;
    esac
  done

  # remove unneeded architectures
  rm -rf "${pkgdir}"/usr/src/linux-${_kernver}/arch/{alpha,arm,arm26,avr32,blackfin,c6x,cris,frv,h8300,hexagon,ia64,m32r,m68k,m68knommu,mips,microblaze,mn10300,openrisc,parisc,powerpc,ppc,s390,score,sh,sh64,sparc,sparc64,tile,unicore32,um,v850,xtensa}
}
