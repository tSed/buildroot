################################################################################
#
# lapack-reference
#
################################################################################

LAPACK_REFERENCE_VERSION = 3.5.0
LAPACK_REFERENCE_SOURCE = lapack-$(LAPACK_REFERENCE_VERSION).tgz
LAPACK_REFERENCE_LICENSE = BSD-3c
LAPACK_REFERENCE_LICENSE_FILES = LICENSE lapacke/LICENSE
LAPACK_REFERENCE_SITE = http://www.netlib.org/lapack
LAPACK_REFERENCE_INSTALL_STAGING = YES

# Enable C-API lapacke:
LAPACK_REFERENCE_CONF_OPTS = -DLAPACKE=ON

$(eval $(cmake-package))
