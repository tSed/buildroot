#!/bin/bash

# Copyright (C) 2015 by Samuel Martin <s.martin49@gmail.com>
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

#
# Usage:
#
#   ./support/scripts/list-toolchain-features.sh CROSS_COMPILE
#
# Description:
#
#   This script performs a series of basic tests on a cross-toolchain and
#   prints out the default toolchain's configuration.
#   The cross-toolchain is describe by the CROSS_COMPILE prefix (similar to
#   the Linux kernel variable).
#
# Output:
#
#   The output configuration fragment may contain more entries than needed
#   in a defconfig. You can inject this configuration in a Buildroot
#   configuration to generate the corresponding defconfig.
#
#   The output configuration fragment may need some additional fixes:
#   * <FIXME> tags must be replaced with something correct;
#   * missing entries (non-exhaustive list):
#       - Target CPU (e.g. BR2_cortex_a9, BR2_x86_atom)
#       - Target FPU (e.g.: BR2_ARM_ENABLE_NEON, BR2_ARM_FPU_VFPV2)
#       - Target ABI details (BR2_MIPS_NABI64, BR2_MIPS_SOFT_FLOAT)
#

## TODO:
## - warning if unusable toolchain
## - check for TLS?
## - check for libmudflap? (removed from gcc since 4.9, see:
##     https://gcc.gnu.org/wiki/Mudflap_Pointer_Debugging )

usage() {
  printf "
usage: ${0##*/} [OPTIONS] -- CROSS_COMPILE [TARGET_CFLAGS...]

description:
\tTest the given cross-compiler for features optons supported in Buildroot, and
\tgenerate the requested output.

options:
\t-f,--format FORMAT
\t\tGenerate output in the given format.
\t\tAllowed formats are: .config, Config.in (default: .config).
\t\t- .config format generates the .config fragment with all enabled and
\t\t  disabled symbols.
\t\t  This is not the defconfig fragment; to get it you need to:
\t\t  1. generate the .config fragment;
\t\t  2. inject this .config fragment in a new build config;
\t\t  3. run 'make savedefconfig' to generate the corresponding defconfig.
\t\t- Config.in format generates a stub of config entry with its selection.

\t-c,--custom
\t\tGenerate entry for custom external toolchain instead of for supported
\t\ttoolchain.\n\n"
}

#
# Utilities
#

log() {
  printf >&2 "$@"
}

warning() {
  log "\nwarning: $@\n"
  return 0
}

error() {
  local ret=$?
  log "\nerror:  $@\n"
  return ${ret}
}

# $n: message
die() {
  error "${@}"
  usage >&2
  exit 1
}

declare -a REMAINS_ARGS
declare CUSTOM_TOOLCHAIN
declare FORMAT=.config

while test ${#} -gt 0 ; do
  case "${1}" in
    -h|--help)
      usage
      exit
      ;;
    -c|--custom*)
      CUSTOM_TOOLCHAIN=1
      ;;
    -f|--format)
      shift
      FORMAT="${1}"
      ;;
    --)
      shift
      REMAINS_ARGS+=( ${@} )
      break
      ;;
    *)
      REMAINS_ARGS+=( "${1}" )
      ;;
  esac
  shift
done
case "${FORMAT}" in
  .config|Config.in) ;;
  *) die "Unsupported output type: '${FORMAT}'\n\
\tSupported output type: .config, Config.in"
   ;;
esac
set -- ${REMAINS_ARGS[@]}
unset REMAINS_ARGS

#
# Formating stuff
#
declare -A SYMBOLS
if test -n "${CUSTOM_TOOLCHAIN}" ; then
  SYMBOLS=(\
    ["custom"]="BR2_TOOLCHAIN_EXTERNAL_CUSTOM" \
    ["prefix"]="BR2_TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX" \
    ["download"]="BR2_TOOLCHAIN_EXTERNAL_DOWNLOAD" \
    ["url"]="BR2_TOOLCHAIN_EXTERNAL_URL" \
    ["gcc"]="BR2_TOOLCHAIN_EXTERNAL_GCC_" \
    ["headers"]="BR2_TOOLCHAIN_EXTERNAL_HEADERS_" \
    ["uclibc"]="BR2_TOOLCHAIN_EXTERNAL_CUSTOM_UCLIBC" \
    ["glibc"]="BR2_TOOLCHAIN_EXTERNAL_CUSTOM_GLIBC" \
    ["musl"]="BR2_TOOLCHAIN_EXTERNAL_CUSTOM_MUSL" \
    ["wchar"]="BR2_TOOLCHAIN_EXTERNAL_WCHAR" \
    ["rpc"]="BR2_TOOLCHAIN_EXTERNAL_INET_RPC" \
    ["locale"]="BR2_TOOLCHAIN_EXTERNAL_LOCALE" \
    ["threads"]="BR2_TOOLCHAIN_EXTERNAL_HAS_THREADS" \
    ["threads_debug"]="BR2_TOOLCHAIN_EXTERNAL_HAS_THREADS_DEBUG" \
    ["threads_nptl"]="BR2_TOOLCHAIN_EXTERNAL_HAS_THREADS_NPTL" \
    ["ssp"]="BR2_TOOLCHAIN_EXTERNAL_HAS_SSP" \
    ["cxx"]="BR2_TOOLCHAIN_EXTERNAL_CXX" \
    ["fortran"]="BR2_TOOLCHAIN_EXTERNAL_FORTRAN" \
    ["openmp"]="BR2_TOOLCHAIN_EXTERNAL_OPENMP" \
    ["lto"]="BR2_TOOLCHAIN_EXTERNAL_LTO" \
    ["graphite"]="BR2_TOOLCHAIN_EXTERNAL_GRAPHITE" \
  )
else
  SYMBOLS=(\
    ["custom"]="" \
    ["prefix"]="" \
    ["download"]="" \
    ["url"]="" \
    ["gcc"]="BR2_TOOLCHAIN_GCC_AT_LEAST_" \
    ["headers"]="BR2_TOOLCHAIN_HEADERS_AT_LEAST_" \
    ["uclibc"]="BR2_TOOLCHAIN_USES_UCLIBC" \
    ["glibc"]="BR2_TOOLCHAIN_EXTERNAL_GLIBC" \
    ["musl"]="BR2_TOOLCHAIN_EXTERNAL_MUSL" \
    ["wchar"]="BR2_USE_WCHAR" \
    ["rpc"]="BR2_TOOLCHAIN_HAS_NATIVE_RPC" \
    ["locale"]="BR2_ENABLE_LOCALE" \
    ["threads"]="BR2_TOOLCHAIN_HAS_THREADS" \
    ["threads_debug"]="BR2_TOOLCHAIN_HAS_THREADS_DEBUG" \
    ["threads_nptl"]="BR2_TOOLCHAIN_HAS_THREADS_NPTL" \
    ["ssp"]="BR2_TOOLCHAIN_HAS_SSP" \
    ["cxx"]="BR2_INSTALL_LIBSTDCPP" \
    ["fortran"]="BR2_TOOLCHAIN_HAS_FORTRAN" \
    ["openmp"]="BR2_TOOLCHAIN_HAS_OPENMP" \
    ["lto"]="BR2_TOOLCHAIN_HAS_LTO" \
    ["graphite"]="BR2_TOOLCHAIN_HAS_GRAPHITE" \
  )
fi


# $1: symbol name
# $2: symbol value
format_dot_config() {
  local symbol="${1}" prop_val="${2}"

  if test -z "${prop_val}" ; then
    printf "# ${symbol} is not set\n"
  else
    case "${prop_val}" in
      y)     printf "${symbol}=y\n" ;;
      \"*\") printf "${symbol}=${prop_val}\n" ;;
      *)     printf "${symbol}${prop_val}=y\n" ;;
    esac
  fi
}

# $1: symbol name
# $2: symbol value
format_config_in() {
  local symbol="${1}" prop_val="${2}"

  if test -z "${prop_val}" ; then
    return
  else
    case "${prop_val}" in
      y)     printf "\tselect ${symbol}\n" ;;
      \"*\") return ;;
      *)     printf "\tselect ${symbol}${prop_val}\n" ;;
    esac
  fi
}

# $1: symbol name
# $2: symbol value
format_entry() {
  local symbol=${SYMBOLS[${1}]}
  shift
  if test -z "${symbol}" ; then
    return
  fi

  case "${FORMAT}" in
    .config)
      format_dot_config "${symbol}" $@
      ;;
    Config.in)
      format_config_in  "${symbol}" $@
      ;;
    *)
      die "Unsupported output: '${FORMAT}'"
      ;;
  esac
}

#
# Cross-toolchain test functions
#

test_executable_works() {
  test -e ${1} || error "Cannot find executable: '${1}'" || return $?
  test -x ${1} || error "Not an executable: ${1}" || return $?
  ${1} --version >/dev/null 2>&1 || die "Executable does not work: ${1}"
}

get_sysroot() {
  ${1} -print-sysroot 2>/dev/null ||
  ${1} -print-search-dirs 2>/dev/null |
    sed -nre '/^libraries:/ s/[: =]+/\n/gp' | grep -oE '.*/(sysroot|runtime)/' | uniq
}

# $1: sysroot path
get_kernel_headers_version() {
  local hostcc=$(which gcc)
  test_executable_works ${hostcc} || error "Cannot find host C compiler" || return $?
  env HOSTCC=${hostcc} ${0%/*}/check-kernel-headers.sh "${1}" 0.0 |
  sed -nre '/.* got ([0-9]+\.[0-9]+.*)/ s//\1/p' |
  sed -re 's/([0-9]+(.[0-9]+)*).*$/\1/ ; s/\./_/g'
}

# $1: cross-gcc path
get_gcc_version() {
	${1} --version |
    sed -r -e '1!d; s/^[^)]+\) ([^[:space:]]+).*/\1/;' |
    sed -r -e 's/([0-9]+\.[0-9]+).*/\1/; s/(\.0)+$//; s/\./_/g'
}

# $n: cross-gcc path + target cflags
test_has_LFS() {
  printf '#include <sys/types.h>\n#include <sys/stat.h>\n#include <fcntl.h>\nint main(void) { open64("foo", "r"); return 0; }\n' |
  ${@} -x c -o /dev/null - -D_FILE_OFFSET_BITS=64 2>/dev/null
}

# $n: cross-gcc path + target cflags
test_has_IPV6() {
  printf '#include <net/route.h>\nint main(void) { struct in6_rtmsg foo; return 0; }\n' |
  ${@} -x c -o /dev/null - 2>/dev/null
}

# $n: cross-gcc path + target cflags
test_has_MMU() {
  printf '#include <unistd.h>\nint main (void) { fork(); return 0; }\n' |
  ${@} -x c -o /dev/null - 2>/dev/null
}

# $n: cross-gcc path + target cflags
test_has_WCHAR() {
  printf '#include <stddef.h>\nint main(void) { wchar_t a = 0; return 0; }\n' |
  ${@} -x c -o /dev/null - 2>/dev/null
}

# $1: sysroot directory
test_has_RPC() {
  test -f ${1}/usr/include/rpc/rpc.h
}

# $1: sysroot directory
test_use_glibc() {
  test $(find ${1}/ -maxdepth 2 -name 'ld-linux*.so.*' -o -name 'ld.so.*' -o -name 'ld64.so.*' | wc -l) -ne 0
}

# $1: sysroot directory
test_use_musl() {
  test -f ${1}/lib/libc.so -a ! -e ${1}/lib/libm.so
}

# $1: sysroot directory
test_use_uclibc() {
  test -f ${1}/usr/include/bits/uClibc_config.h
}

# $1: cross-g++ path
test_has_cplusplus() {
  test_executable_works ${1} 2>/dev/null || return $?
  ${@} -v > /dev/null 2>&1
}

# $1: cross-gfortran path
test_has_fortran() {
  test_executable_works ${1} 2>/dev/null || return $?
  printf 'program hello\n\tprint *, "Hello Fortran!\\n"\nend program hello\n' |
  ${@} -x f95 -o /dev/null - 2>/dev/null
}

# $1: cross-gcc path + target cflags
test_has_openmp() {
  printf '#include <omp.h>\nint main(void) { return omp_get_num_procs(); }\n' |
  ${@} -fopenmp -lgomp -x c -o /dev/null - 2>/dev/null
}

# $1: cross-gcc path + target cflags
test_has_lto() {
  printf '#include <stdio.h>\nint main(void) { printf("Hello LTO!\\n"); }\n' |
  ${@} -flto -x c -o /dev/null - 2>/dev/null
}

# $1: cross-gcc path + target cflags
test_has_graphite() {
  printf '#include <stdio.h>\nint main(void) { printf("Hello Graphite/ISL!\\n"); }\n' |
  ${@} -floop-unroll-and-jam -x c -o /dev/null - 2>/dev/null
}

# $1: libc name
# $2: sysroot dir
# $n: libc args
test_libc_feature() {
  local libc="${1}" sysroot="${2}"
  shift 2
  case "${libc}" in
    uclibc)
      local uclibc_config_file=${sysroot}/usr/include/bits/uClibc_config.h
      if test ! -f ${uclibc_config_file} ; then
        return 1
      fi
      local uclibc_def="${1}"
      grep -q "\#define ${uclibc_def} 1" ${uclibc_config_file}
      ;;
    *)
      true
  esac
}

get_os_libc_abi() {
  local os="${1}" libcabi="${2}" libc abi
  case "${libcabi}" in
    uclinux) os=linux ; libc=uclibc ;;
    uclibc*) libc=uclibc ;;
    gnu*) libc=glibc ;;
    musl*) libc=musl ;;
    "") die "Empty libc/ABI" ;;
    *) libc=${libcabi} ;;
  esac
  case "${libcabi}" in
    *abi*) abi=${libcabi#*${libcabi%?abi*}} ;;
    *gnu*) abi=${libcabi#*gnu} ;;
  esac
  echo "${os}" "${libc}" "${abi}"
}

get_target_tuple() {
  local tuple=( $(${1} -dumpmachine | sed -re 's/^([^-]+)-(([^-]+)-([^-]+)-|([^-]+)-)?([^-]+)$/\1 "\3" "\4\5" \6/') )
  local arch=${tuple[0]} vendor=${tuple[1]//\"/} os=${tuple[2]//\"/} libcabi=${tuple[3]//\"/}
  local oslibcabi=( $(get_os_libc_abi "${os}" "${libcabi}") )
  os=${oslibcabi[0]}
  local libc=${oslibcabi[1]} abi=${oslibcabi[2]}
  echo "\"${arch}\"" "\"${vendor}\"" "\"${os}\"" "\"${libc}\"" "\"${abi}\""
}

#
# main
#

CROSS_COMPILE="${1}"
shift
TARGET_CFLAGS="${@}"

#
# Cross-tool to be used
#
TARGET_CC="${CROSS_COMPILE}gcc"
TARGET_CXX="${CROSS_COMPILE}g++"
TARGET_FC="${CROSS_COMPILE}gfortran"
TARGET_READELF="${CROSS_COMPILE}readelf"

#
# Target tuple
#
test_executable_works ${TARGET_CC} || die "CC not found"
SYSROOT=$(get_sysroot ${TARGET_CC})
TUPLE=( $(get_target_tuple ${TARGET_CC}) )
ARCH=${TUPLE[0]//\"/}
VENDOR=${TUPLE[1]//\"/}
OS=${TUPLE[2]//\"/}
LIBC=${TUPLE[3]//\"/}
ABI=${TUPLE[4]//\"/}

log "Toolchain info:\n"
log "  CROSS_COMPILE=${CROSS_COMPILE}\n"
log "  Target tuple:\n\tarch='${ARCH}'\n\tvendor='${VENDOR}'\n\tos='${OS}'\n\tlibc='${LIBC}'\n\tabi='${ABI}'\n\n"
# Sanity checks
test ! -z "${ARCH}" || die "Cannot get ARCH from '${TARGET_TUPLE}'"
test ! -z "${LIBC}" || die "Cannot get LIBC from '${TARGET_TUPLE}'"
case "${LIBC}" in
  uclibc) test_use_uclibc ${SYSROOT} || die "NOT uclibc" ;;
  glibc)  test_use_glibc ${SYSROOT}  || die "NOT glibc" ;;
  musl)   test_use_musl ${SYSROOT}   || die "NOT musl" ;;
  *)      die "Unsupported libc: '${LIBC}'" ;;
esac
test -e "${TARGET_CC}" || die "Cannot find cross-compiler: ${TARGET_CC}"
test -x "${TARGET_CC}" || die "Cannot execute cross-compiler: ${TARGET_CC}"
test_has_LFS ${TARGET_CC} ${TARGET_CFLAGS}  || warning "Missing required support for: LFS"
test_has_IPV6 ${TARGET_CC} ${TARGET_CFLAGS} || warning "Missing required support for: IPv6"

# Target architecture properties

if test "${FORMAT}" = ".config" ; then
  # may need to hanlde more cases (big/little endian, armvX, etc)
  case "${ARCH}" in
    arm*)
      format_dot_config BR2_arm y
      format_dot_config BR2_$(echo "ARM_${ABI}" | tr '[:lower:]' '[:upper:]') y
      #target cpu: TODO (e.g.: BR2_cortex-a15=y)
      #target fpu: TODO (e.g.: BR2_ARM_ENABLE_NEON=y, BR2_ARM_FPU_VFPV2=y)
      ;;
    i.86)
      format_dot_config BR2_i386 y
      ;;
    *)
      format_dot_config BR2_${ARCH} y
      ;;
  esac
  format_dot_config BR2_USE_MMU $(test_has_MMU ${TARGET_CC} ${TARGET_CFLAGS} && echo y)
fi


# Toolchain properties

if test "${FORMAT}" = ".config" ; then
  format_dot_config "BR2_TOOLCHAIN_EXTERNAL" y
elif test "${FORMAT}" = "Config.in" ; then
  printf "config BR2_TOOLCHAIN_EXTERNAL_<FIXME>\n"
  printf "\tbool \"<FIXME>\"\n"
  case "${ARCH}" in
    arm*)
      printf "\tdepends on BR2_arm\n"
      printf "\tdepends on BR2_$(echo "ARM_${ABI}" | tr '[:lower:]' '[:upper:]')\n"
      #target cpu: TODO (e.g.: BR2_cortex-a15=y)
      #target fpu: TODO (e.g.: BR2_ARM_ENABLE_NEON=y, BR2_ARM_FPU_VFPV2=y)
      ;;
    i.86)
      printf "\tdepends on BR2_i386\n"
      ;;
    *)
      printf "\tdepends on BR2_${ARCH}\n"
      ;;
  esac
fi

format_entry custom   y
format_entry download y
format_entry url      '"FIXME"'
format_entry gcc      $(get_gcc_version ${TARGET_CC})
format_entry headers  $(get_kernel_headers_version ${SYSROOT})

case "${LIBC}" in
  uclibc)
    format_entry uclibc  y
    format_entry wchar   $(test_has_WCHAR ${TARGET_CC} ${TARGET_CFLAGS} && echo y)
    format_entry rpc     $(test_has_RPC ${SYSROOT} && echo y)
    format_entry locale  $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_LOCALE__ && echo y)
    format_entry threads $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_THREADS__ && echo y)
    format_entry threads_debug $(test_libc_feature ${LIBC} ${SYSROOT} __PTHREADS_DEBUG_SUPPORT__ && echo y)
    format_entry threads_nptl  $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_THREADS_NATIVE__ && echo y)
    format_entry ssp     $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_SSP__ && echo y)
    ;;
  glibc)
    format_entry glibc   y
    #format_entry wchar   $(test_has_WCHAR ${TARGET_CC} ${TARGET_CFLAGS} && echo y)
    format_entry rpc     $(test_has_RPC ${SYSROOT} && echo y)
    #format_entry locale  $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_LOCALE__ && echo y)
    #format_entry threads $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_THREADS__ && echo y)
    #format_entry threads_debug $(test_libc_feature ${LIBC} ${SYSROOT} __PTHREADS_DEBUG_SUPPORT__ && echo y)
    #format_entry threads_nptl  $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_THREADS_NATIVE__ && echo y)
    #format_entry ssp     $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_SSP__ && echo y)
    ;;
  musl)
    format_entry musl    y
    #format_entry wchar   $(test_has_WCHAR ${TARGET_CC} ${TARGET_CFLAGS} && echo y)
    format_entry rpc     $(test_has_RPC ${SYSROOT} && echo y)
    #format_entry locale  $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_LOCALE__ && echo y)
    #format_entry threads $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_THREADS__ && echo y)
    #format_entry threads_debug $(test_libc_feature ${LIBC} ${SYSROOT} __PTHREADS_DEBUG_SUPPORT__ && echo y)
    #format_entry threads_nptl  $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_THREADS_NATIVE__ && echo y)
    #format_entry ssp     $(test_libc_feature ${LIBC} ${SYSROOT} __UCLIBC_HAS_SSP__ && echo y)
    ;;
esac

format_entry cxx      $(test_has_cplusplus ${TARGET_CXX} && echo y)
format_entry fortran  $(test_has_fortran ${TARGET_FC} && echo y)
format_entry openmp   $(test_has_openmp ${TARGET_CC} ${TARGET_CFLAGS} && echo y)
format_entry lto      $(test_has_lto ${TARGET_CC} ${TARGET_CFLAGS} && echo y)
format_entry graphite $(test_has_graphite ${TARGET_CC} ${TARGET_CFLAGS} && echo y)

## #
## # Check that the cross-compiler given in the configuration exists
## #
## # $1: cross-gcc path
## #
## check_cross_compiler_exists() {
## 	__CROSS_CC=${$1} ; \
## 	${__CROSS_CC} -v > /dev/null 2>&1 ; \
## 	if test $? -ne 0 ; then \
## 		echo "Cannot execute cross-compiler '${__CROSS_CC}'" ; \
## 		return 1 ; \
## 	fi
##
## #
## # Check for toolchains known not to work with Buildroot. For now, we
## # only check for Angstrom toolchains, by looking at the vendor part of
## # the host tuple.
## #
## # $1: cross-gcc path
## #
## check_unusable_toolchain() {
## 	__CROSS_CC=${$1} ; \
## 	vendor=`${__CROSS_CC} -dumpmachine | cut -f2 -d'-'` ; \
## 	if test "${vendor}" = "angstrom" ; then \
## 		echo "Angstrom toolchains are not pure toolchains: they contain" ; \
## 		echo "many other libraries than just the C library, which makes" ; \
## 		echo "them unsuitable as external toolchains for build systems" ; \
## 		echo "such as Buildroot." ; \
## 		return 1 ; \
## 	fi; \
## 	with_sysroot=`${__CROSS_CC} -v 2>&1 |sed -r -e '/.* --with-sysroot=([^[:space:]]+)[[:space:]].*/!d; s//\1/'`; \
## 	if test "${with_sysroot}"  = "/" ; then \
## 		echo "Distribution toolchains are unsuitable for use by Buildroot," ; \
## 		echo "as they were configured in a way that makes them non-relocatable,"; \
## 		echo "and contain a lot of pre-built libraries that would conflict with"; \
## 		echo "the ones Buildroot wants to build."; \
## 		return 1; \
## 	fi
