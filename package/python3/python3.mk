################################################################################
#
# python3
#
################################################################################

PYTHON3_VERSION_MAJOR = 3.5
PYTHON3_VERSION = $(PYTHON3_VERSION_MAJOR).1
PYTHON3_SOURCE = Python-$(PYTHON3_VERSION).tar.xz
PYTHON3_SITE = http://python.org/ftp/python/$(PYTHON3_VERSION)
PYTHON3_LICENSE = Python software foundation license v2, others
PYTHON3_LICENSE_FILES = LICENSE

# Python itself doesn't use libtool, but it includes the source code
# of libffi, which uses libtool. Unfortunately, it uses a beta version
# of libtool for which we don't have a matching patch. However, this
# is not a problem, because we don't use the libffi copy included in
# the Python sources, but instead use an external libffi library.
PYTHON3_LIBTOOL_PATCH = NO

# Force python ABIs (those settings reflect the defaults for the configure
# script).
# For further details, refer to PEP 3149:
#   https://www.python.org/dev/peps/pep-3149/
PYTHON3_PYDEBUG = NO
PYTHON3_PYMALLOC = YES
PYTHON3_WIDE_UNICODE = NO
PYTHON3_ABI = $(subst $(space),,\
	$(if $(filter YES,$(PYTHON3_PYDEBUG)),d) \
	$(if $(filter YES,$(PYTHON3_PYMALLOC)),m) \
	$(if $(BR2_USE_WCHAR),$(if $(filter YES,$(PYTHON3_WIDE_UNICODE)),u)) \
)
HOST_PYTHON3_ABI = $(subst $(space),,\
	$(if $(filter YES,$(PYTHON3_PYDEBUG)),d) \
	$(if $(filter YES,$(PYTHON3_PYMALLOC)),m) \
	$(if $(filter YES,$(PYTHON3_WIDE_UNICODE)),u) \
)

# Python needs itself and a "pgen" program to build itself, both being
# provided in the Python sources. So in order to cross-compile Python,
# we need to build a host Python first. This host Python is also
# installed in $(HOST_DIR), as it is needed when cross-compiling
# third-party Python modules.

HOST_PYTHON3_CONF_OPTS += 	\
	--without-ensurepip	\
	--without-cxx-main 	\
	--disable-sqlite3	\
	--disable-tk		\
	--with-expat=system	\
	--disable-curses	\
	--disable-codecs-cjk	\
	--disable-nis		\
	--enable-unicodedata	\
	--disable-test-modules	\
	--disable-idle3		\
	--disable-ossaudiodev

ifeq ($(PYTHON3_PYDEBUG),YES)
HOST_PYTHON3_CONF_OPTS += --with-pydebug
else
HOST_PYTHON3_CONF_OPTS += --without-pydebug
endif

ifeq ($(PYTHON3_PYMALLOC),YES)
HOST_PYTHON3_CONF_OPTS += --with-pymalloc
else
HOST_PYTHON3_CONF_OPTS += --without-pymalloc
endif

ifeq ($(PYTHON3_WIDE_UNICODE),YES)
HOST_PYTHON3_CONF_OPTS += --with-wide-unicode
else
HOST_PYTHON3_CONF_OPTS += --without-wide-unicode
endif

# python*-config scripts:
# In the staging tree:
#  	there is only one version of the python interpreter, thus all *-config
#  	scripts must be fixed.
# In the host tree:
# 	if python3 is enabled, the python-config script is installed; so
# 	reflect this in the list of scripts to be fixed.
PYTHON3_CONFIG_SCRIPTS_COMMON = \
	python$(PYTHON3_VERSION_MAJOR)-config \
	python3-config

PYTHON3_CONFIG_SCRIPTS = \
	python$(PYTHON3_VERSION_MAJOR)$(PYTHON3_ABI)-config \
	$(PYTHON3_CONFIG_SCRIPTS_COMMON)

HOST_PYTHON3_CONFIG_SCRIPTS = \
	python$(PYTHON3_VERSION_MAJOR)$(HOST_PYTHON3_ABI)-config \
	$(PYTHON3_CONFIG_SCRIPTS_COMMON) \
	$(if $(BR2_PACKAGE_PYTHON3),python-config)

# Make sure that LD_LIBRARY_PATH overrides -rpath.
# This is needed because libpython may be installed at the same time that
# python is called.
HOST_PYTHON3_CONF_ENV += \
	LDFLAGS="$(HOST_LDFLAGS) -Wl,--enable-new-dtags"

PYTHON3_DEPENDENCIES = host-python3 libffi

HOST_PYTHON3_DEPENDENCIES = host-expat host-zlib

PYTHON3_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_PYTHON3_READLINE),y)
PYTHON3_DEPENDENCIES += readline
endif

ifeq ($(BR2_PACKAGE_PYTHON3_CURSES),y)
PYTHON3_DEPENDENCIES += ncurses
else
PYTHON3_CONF_OPTS += --disable-curses
endif

ifeq ($(BR2_PACKAGE_PYTHON3_DECIMAL),y)
PYTHON3_DEPENDENCIES += mpdecimal
PYTHON3_CONF_OPTS += --with-libmpdec=system
else
PYTHON3_CONF_OPTS += --with-libmpdec=none
endif

ifeq ($(BR2_PACKAGE_PYTHON3_PYEXPAT),y)
PYTHON3_DEPENDENCIES += expat
PYTHON3_CONF_OPTS += --with-expat=system
else
PYTHON3_CONF_OPTS += --with-expat=none
endif

ifeq ($(BR2_PACKAGE_PYTHON3_PYC_ONLY),y)
PYTHON3_CONF_OPTS += --enable-old-stdlib-cache
endif

ifeq ($(BR2_PACKAGE_PYTHON3_SQLITE),y)
PYTHON3_DEPENDENCIES += sqlite
else
PYTHON3_CONF_OPTS += --disable-sqlite3
endif

ifeq ($(BR2_PACKAGE_PYTHON3_SSL),y)
PYTHON3_DEPENDENCIES += openssl
endif

ifneq ($(BR2_PACKAGE_PYTHON3_CODECSCJK),y)
PYTHON3_CONF_OPTS += --disable-codecs-cjk
endif

ifneq ($(BR2_PACKAGE_PYTHON3_UNICODEDATA),y)
PYTHON3_CONF_OPTS += --disable-unicodedata
endif

ifeq ($(BR2_PACKAGE_PYTHON3_BZIP2),y)
PYTHON3_DEPENDENCIES += bzip2
endif

ifeq ($(BR2_PACKAGE_PYTHON3_ZLIB),y)
PYTHON3_DEPENDENCIES += zlib
endif

ifeq ($(BR2_PACKAGE_PYTHON3_OSSAUDIODEV),y)
PYTHON3_CONF_OPTS += --enable-ossaudiodev
else
PYTHON3_CONF_OPTS += --disable-ossaudiodev
endif

PYTHON3_CONF_ENV += \
	ac_cv_have_long_long_format=yes \
	ac_cv_file__dev_ptmx=yes \
	ac_cv_file__dev_ptc=yes \
	ac_cv_working_tzset=yes

# uClibc is known to have a broken wcsftime() implementation, so tell
# Python 3 to fall back to strftime() instead.
ifeq ($(BR2_TOOLCHAIN_USES_UCLIBC),y)
PYTHON3_CONF_ENV += ac_cv_func_wcsftime=no
endif

PYTHON3_CONF_OPTS += \
	--without-ensurepip	\
	--without-cxx-main 	\
	--with-system-ffi	\
	--disable-pydoc		\
	--disable-test-modules	\
	--disable-lib2to3	\
	--disable-tk		\
	--disable-nis		\
	--disable-idle3		\
	--disable-pyo-build

ifeq ($(PYTHON3_PYDEBUG),YES)
PYTHON3_CONF_OPTS += --with-pydebug
else
PYTHON3_CONF_OPTS += --without-pydebug
endif

ifeq ($(PYTHON3_PYMALLOC),YES)
PYTHON3_CONF_OPTS += --with-pymalloc
else
PYTHON3_CONF_OPTS += --without-pymalloc
endif

ifeq ($(PYTHON3_WIDE_UNICODE)-$(BR2_USE_WCHAR),YES-y)
PYTHON3_CONF_OPTS += --with-wide-unicode
else
PYTHON3_CONF_OPTS += --without-wide-unicode
endif

# This is needed to make sure the Python build process doesn't try to
# regenerate those files with the pgen program. Otherwise, it builds
# pgen for the target, and tries to run it on the host.

define PYTHON3_TOUCH_GRAMMAR_FILES
	touch $(@D)/Include/graminit.h $(@D)/Python/graminit.c
endef

# This prevents the Python Makefile from regenerating the
# Python/importlib.h header if Lib/importlib/_bootstrap.py has changed
# because its generation is broken in a cross-compilation environment
# and importlib.h is not used.

define PYTHON3_TOUCH_IMPORTLIB_H
	touch $(@D)/Python/importlib.h
endef
HOST_PYTHON3_POST_INSTALL_HOOKS += HOST_PYTHON3_INSTALL_TOOLS

PYTHON3_CONF_ENV += \
	PGEN_FOR_BUILD=$(HOST_DIR)/usr/bin/python-pgen \
	FREEZE_IMPORTLIB_FOR_BUILD=$(HOST_DIR)/usr/bin/python-freeze-importlib

#
# Remove useless files. In the config/ directory, only the Makefile
# and the pyconfig.h files are needed at runtime.
#
define PYTHON3_REMOVE_USELESS_FILES
	rm -f $(TARGET_DIR)/usr/bin/smtpd.py.3
	for i in `find $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/config-$(PYTHON3_VERSION_MAJOR)m/ \
		-type f -not -name pyconfig.h -a -not -name Makefile` ; do \
		rm -f $$i ; \
	done
	rm -rf $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/__pycache__/
	rm -rf $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/lib-dynload/sysconfigdata/__pycache__
	rm -rf $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/collections/__pycache__
	rm -rf $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/importlib/__pycache__
endef

PYTHON3_POST_INSTALL_TARGET_HOOKS += PYTHON3_REMOVE_USELESS_FILES

#
# Make sure libpython gets stripped out on target
#
define PYTHON3_ENSURE_LIBPYTHON_STRIPPED
	chmod u+w $(TARGET_DIR)/usr/lib/libpython$(PYTHON3_VERSION_MAJOR)*.so
endef

PYTHON3_POST_INSTALL_TARGET_HOOKS += PYTHON3_ENSURE_LIBPYTHON_STRIPPED

PYTHON3_AUTORECONF = YES

define PYTHON3_INSTALL_SYMLINK
	ln -fs python3 $(TARGET_DIR)/usr/bin/python
endef

ifneq ($(BR2_PACKAGE_PYTHON),y)
PYTHON3_POST_INSTALL_TARGET_HOOKS += PYTHON3_INSTALL_SYMLINK
endif

# Some packages may have build scripts requiring python3, whatever is the
# python version chosen for the target.
# Only install the python symlink in the host tree if python3 is enabled
# for the target.
ifeq ($(BR2_PACKAGE_PYTHON3),y)
define HOST_PYTHON3_INSTALL_SYMLINK
	ln -fs python3 $(HOST_DIR)/usr/bin/python
	ln -fs python3-config $(HOST_DIR)/usr/bin/python-config
endef

HOST_PYTHON3_POST_INSTALL_HOOKS += HOST_PYTHON3_INSTALL_SYMLINK
endif

# Provided to other packages
PYTHON3_PATH = $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/sysconfigdata/:$(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/

$(eval $(autotools-package))
$(eval $(host-autotools-package))

define PYTHON3_CREATE_PYC_FILES
	PYTHONPATH="$(PYTHON3_PATH)" \
	$(HOST_DIR)/usr/bin/python$(PYTHON3_VERSION_MAJOR) \
		support/scripts/pycompile.py \
		$(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)
endef

ifeq ($(BR2_PACKAGE_PYTHON3_PYC_ONLY)$(BR2_PACKAGE_PYTHON3_PY_PYC),y)
TARGET_FINALIZE_HOOKS += PYTHON3_CREATE_PYC_FILES
endif

ifeq ($(BR2_PACKAGE_PYTHON3_PYC_ONLY),y)
define PYTHON3_REMOVE_PY_FILES
	find $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR) -name '*.py' -print0 | \
		xargs -0 --no-run-if-empty rm -f
endef
TARGET_FINALIZE_HOOKS += PYTHON3_REMOVE_PY_FILES
endif

# Normally, *.pyc files should not have been compiled, but just in
# case, we make sure we remove all of them.
ifeq ($(BR2_PACKAGE_PYTHON3_PY_ONLY),y)
define PYTHON3_REMOVE_PYC_FILES
	find $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR) -name '*.pyc' -print0 | \
		xargs -0 --no-run-if-empty rm -f
endef
TARGET_FINALIZE_HOOKS += PYTHON3_REMOVE_PYC_FILES
endif

# In all cases, we don't want to keep the optimized .opt-1.pyc and
# .opt-2.pyc files, since they can't work without their non-optimized
# variant.
ifeq ($(BR2_PACKAGE_PYTHON3),y)
define PYTHON3_REMOVE_OPTIMIZED_PYC_FILES
	find $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR) -name '*.opt-1.pyc' -print0 -o -name '*.opt-2.pyc' -print0 | \
		xargs -0 --no-run-if-empty rm -f
endef
TARGET_FINALIZE_HOOKS += PYTHON3_REMOVE_OPTIMIZED_PYC_FILES
endif
