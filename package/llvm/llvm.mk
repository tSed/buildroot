################################################################################
#
# llvm
#
################################################################################

LLVM_VERSION = 3.6.1
LLVM_SITE = http://llvm.org/releases/$(LLVM_VERSION)
LLVM_SOURCE = llvm-$(LLVM_VERSION).src.tar.xz
LLVM_LICENSE = University of Illinois/NCSA Open Source License
LLVM_LICENSE_FILES = LICENSE.TXT

HOST_LLVM_DEPENDENCIES = host-libxml2 host-zlib host-python

HOST_LLVM_ENABLED_TARGETS := \
	$(shell echo $(ARCH) | \
	sed -e s/i.86/x86/ \
	    -e s/sun4u/sparc/ \
	    -e s/arm64.*/arm64/ \
	    -e s/arm.*/arm/ \
	    -e s/sa110/arm/ \
	    -e s/ppc.*/powerpc/ \
	    -e s/mips.*/mips/\
	    -e s/macppc/powerpc/\
	    -e s/sh.*/sh/),cpp,\
	$(if $(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_R600),r600)

HOST_LLVM_CONF_OPTS = \
	--with-default-sysroot=$(STAGING_DIR) \
	--enable-bindings=none \
	--enable-targets=$(HOST_LLVM_ENABLED_TARGETS) \
	--target=$(GNU_TARGET_NAME)

# Exported variables, to be used in other packages
HOST_LLVM_EXE_PREFIX := $(HOST_DIR)/usr/bin/$(GNU_TARGET_NAME)-llvm
HOST_LLVM_CONFIG := $(HOST_LLVM_EXE_PREFIX)-config
HOST_LLVM_TBLGEN := $(HOST_LLVM_EXE_PREFIX)-tblgen

$(eval $(host-autotools-package))
