CMAKE ?= cmake

ifeq (,$(call suitable-host-package,cmake,$(CMAKE)))
BUILD_HOST_CMAKE = YES
CMAKE = $(HOST_DIR)/usr/bin/cmake
endif
