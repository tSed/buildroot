# Copyright (C) 2016 Samuel Martin <s.martin49@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

# Toolchain helpers
#
# This module defines the following functions:
#   toolchain.
#
# This module is sensitive to the following environment variables:
#

source.declare_module toolchain

toolchain.kernel_headers.detect_version() {
    local sysroot="${1}" kernel_version="${2}"
    toolchain.check_kernel_headers_version "${sysroot}" "${kernel_version}" |
        sed -re 's/.* got ([0-9]+\.[0-9]+)\.x.*/!d ; s//\1/'
}

toolchain.kernel_headers.check_version() {
    local sysroot="${1}" kernel_version="${2}"
    ${TOPDIR}/support/scripts/check-kernel-headers.sh "${sysroot}" \
        "${kernel_version}"
}

toolchain.gcc.detect_version() {
    local cc_path="${1}"
    "${cc_path}" --version |
        sed -r -e '1!d; s/^[^)]+\) ([^[:space:]]+).*/\1/;'
}

toolchain.gcc.check_version() {
    local cc_path="${1}" expected_version="${2}"
    if test -z "$${expected_version}" ; then
        printf "Internal error, gcc version unknown (no GCC_AT_LEAST_X_Y selected)\n"
        return 1
    fi
    local real_version=$(toolchain.detect_gcc_version "${cc_path}")
    if test ! "${real_version}" =~ "^${expected_version}\." ; then
        printf "Incorrect selection of gcc version: expected %s.x, got %s\n" \
            "${expected_version}" "${real_version}"
        return 1
    fi
    return 0
}

toolchain.glibc.has_feature() {
    local feat_symbol="${1}"
    # always true
    echo y
    return 0
}

toolchain.glibc.check_feature() {
    local feat_symbol="${1}" feat_desc="${2}" feat_enabled="${3}"
    if [ "${feat_enabled}" != "$(toolchain.glibc.has_feature "${feat_symbol}")" ] ; then
		echo "${feat_desc} available in C library, please enable ${feat_symbol}"
		return 1
	fi
    return 0
}

toolchain.glibc.has_feature_rpc() {
	local sysroot="${1}"
    if test -f "${sysroot}/usr/include/rpc/rpc.h" ; then
        echo y
        return 0
    fi
    return 1
}

toolchain.glibc.check_feature_rpc() {
    # FIXME: args: what, in what order
    local feat_symbol="RPC" feat_desc="${2}" feat_enabled="${3}"
    local sysroot="${1}"
    local is_in_libc=$(toolchain.glibc.has_feature_rpc "${sysroot}")
	if [ "${feat_symbol}" != "y" -a "${is_in_libc}" = "y" ] ; then
		echo "RPC support available in C library, please enable BR2_TOOLCHAIN_EXTERNAL_INET_RPC"
		return 1
	fi
	if [ "${feat_symbol}" = "y" -a "${is_in_libc}" != "y" ] ; then
		echo "RPC support not available in C library, please disable BR2_TOOLCHAIN_EXTERNAL_INET_RPC"
        return 1
	fi
    return 0
}

toolchain.read_symbol() {
    local dot_config="${1}" symbol="${2}"
    sed -re "/^${symbol}=(.*)/!d ; s//\1/" <"${dot_config}"
}

toolchain.glibc.check() {
    local sysroot="${1}" dot_config="${2}"

}
