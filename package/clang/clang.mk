################################################################################
#
# clang
#
################################################################################

CLANG_VERSION = 3.6.1
CLANG_SITE = http://llvm.org/releases/$(CLANG_VERSION)
CLANG_SOURCE = cfe-$(CLANG_VERSION).src.tar.xz
CLANG_LICENSE = University of Illinois/NCSA Open Source License
CLANG_LICENSE_FILES = LICENSE.TXT

HOST_CLANG_DEPENDENCIES = host-binutils host-llvm host-libxml2
CLANG_SUPPORTS_IN_SOURCE_BUILD = NO

# XXX: libxml2 detection is broken on cmake
HOST_CLANG_CONF_OPTS = \
	-DLLVM_CONFIG=$(HOST_LLVM_CONFIG) \
	-DLLVM_TABLEGEN_EXE=$(HOST_LLVM_TBLGEN) \
	-DDEFAULT_SYSROOT=$(STAGING_DIR) \
	-DGCC_INSTALL_PREFIX=$(HOST_DIR)/usr \
	-DLIBXML2_INCLUDE_DIR=$(HOST_DIR)/usr/include/libxml2 \
	-DLIBXML2_LIBRARIES=$(HOST_DIR)/usr/lib/libxml2.so

$(eval $(host-cmake-package))
