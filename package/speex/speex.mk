################################################################################
#
# speex
#
################################################################################

SPEEX_VERSION = 1.2rc1
SPEEX_SITE = http://downloads.us.xiph.org/releases/speex
SPEEX_LICENSE = BSD-3c
SPEEX_LICENSE_FILES = COPYING

SPEEX_INSTALL_STAGING = YES
SPEEX_DEPENDENCIES = libogg
SPEEX_CONF_OPTS = \
	--with-ogg-libraries=$(STAGING_DIR)/usr/lib \
	--with-ogg-includes=$(STAGING_DIR)/usr/include \
	--enable-fixed-point

ifeq ($(BR2_PACKAGE_SPEEX_ARM4),y)
SPEEX_CONF_OPTS += --enable-arm4-asm
endif

ifeq ($(BR2_PACKAGE_SPEEX_ARM5E),y)
SPEEX_CONF_OPTS += --enable-arm5e-asm
endif

define SPEEX_BUILD_CMDS
	$($(PKG)_MAKE_ENV) $(MAKE) $($(PKG)_MAKE_OPTS) -C $(@D)/$($(PKG)_SUBDIR)
endef

$(eval $(autotools-package))
