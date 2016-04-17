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

# Patchelf helpers
#
# This module defines the following functions:
#   patchelf.set_rpath
#   patchelf.update_rpath
#   patchelf.sanitize_rpath
#
# This module is sensitive to the following environment variables:
#   PATCHELF
#   READELF

source.declare_module patchelf

source.load_module log
source.load_module sdk
source.load_module utils
source.load_module readelf

: ${PATCHELF:=patchelf}

# patchelf.set_xrpath file rpath...
#
# Set RPATH in $file.
# Automatically join all RPATH with the correct separator.
#
# file  : ELF file path
# rpath : RPATH element
#
# environment:
#   PATCHELF: patchelf program path
patchelf.set_rpath() {
    local file="${1}"
    shift
    local rpath="$(sed -e 's/ +/:/g' <<<"${@}")"
    # Sanity check: patchelf needs the ELF file to have a .dynamic section.
    # So, check for it and behaves in a proper way:
    # - returns immediatly if no .dynamic section, and RPATH is empty;
    # - bail out if no .dynamic section and RPATH is not empty.
    if ! readelf.has_section "${file}" '.dynamic' ; then
        if test -z "${rpath}" ; then
            return 0
        else
            local fmt="Trying to set a RPATH to a ELF file with no .dynamic section\n"
            fmt="${fmt}\tfile : %s\n"
            fmt="${fmt}\tRPATH: %s\n"
            log.error "${fmt}" "${file}" "${rpath}" || return 1
        fi
    fi
    "${PATCHELF}" --set-rpath "${rpath}" "${file}"
}

# patchelf.update_rpath basedir binary libdirs...
#
# Set RPATH in $binary computing them from the paths $libdirs (and $basedir).
# Existing RPATH in $file will be overwritten if any.
#
# basedir : absolute path of the tree in which the $bindir and $libdirs must be
# binary  : ELF file absolute path
# libdirs : list of library location (absolute paths)
#
# environment:
#   PATCHELF: patchelf program path
patchelf.update_rpath() {
    local basedir="${1}"
    local binary="${2}"
    shift 2
    local libdirs=( ${@} )
    log.debug "  basedir: %s\n" "${basedir}"
    log.debug "      elf: %s\n" "${binary}"
    log.debug "  libdirs: %s\n" "${libdirs[*]}"
    log.info  "    rpath: %s\n" \
        "$(sdk.compute_rpath "${basedir}" "${binary%/*}" ${libdirs[@]})"
    patchelf.set_rpath "${binary}" \
        "$(sdk.compute_rpath "${basedir}" "${binary%/*}" ${libdirs[@]})"
}

# patchelf.sanitize_rpath basedir binary [keep_lib_usr_lib]
#
# Scan $binary's RPATH, remove any of them pointing outside of $basedir.
# If $keep_lib_usr_lib in not empty, the library directories $basedir/lib and
# $basedir/usr/lib will be added to the RPATH.
#
# Note:
#     Absolute paths is needed to correctly handle symlinks and or mount-bind in
#     the $basedir path.
#
# basedir          : absolute path of the tree in which the $bindir and $libdirs
#                    must be
# binary           : ELF file absolute path
# keep_lib_usr_lib : add to RPATH $basedir/lib and $basedir/usr/lib
#
# environment:
#   PATCHELF: patchelf program path
#   READELF : readelf program path
patchelf.sanitize_rpath() {
    local basedir="$(readlink -f "${1}")"
    local binary="${2}"
    local keep_lib_usr_lib="${3}"

    readelf.is_elf_shared_object "${binary}" ||
        readelf.is_elf_executable "${binary}" ||
            return 0

    local path abspath rpath
    local libdirs=()

    if test -n "${keep_lib_usr_lib}" ; then
        libdirs+=( "${basedir}/lib" "${basedir}/usr/lib" )
    fi

    log.info "ELF: %s\n" "${binary}"

    local rpaths="$(readelf.get_rpath "${binary}")"

    for rpath in ${rpaths//:/ } ; do
        # figure out if we should keep or discard the path; there are several
        # cases to handled:
        # - $path starts with "$ORIGIN":
        #     The original build-system already took care of setting a relative
        #     RPATH, resolve it and test if it is worthwhile to keep it;
        # - $basedir/$path exists:
        #     The original build-system already took care of setting an absolute
        #     RPATH (absolute in the final rootfs), resolve it and test if it is
        #     worthwhile to keep it;
        # - $path start with $basedir:
        #     The original build-system added some absolute RPATH (absolute on
        #     the build machine). While this is wrong, it can still be fixed; so
        #     test if it is worthwhile to keep it;
        # - $path points somewhere else:
        #     (can be anywhere: build trees, staging tree, host location,
        #     non-existing location, etc.)
        #     Just discard such a path.
        if grep -q '^$ORIGIN/' <<<"${rpath}" ; then
            path="${binary%/*}/${rpath#*ORIGIN/}"
        elif test -e "${basedir}/${rpath}" ; then
            path="${basedir}/${rpath}"
        elif grep -q "^${basedir}/" <<<"$(readlink -f "${rpath}")" ; then
            path="${rpath}"
        else
            log.debug "\tDROPPED [out-of-tree]: %s\n" "${rpath}"
            continue
        fi

        abspath="$(readlink -f "${path}")"

        # discard path pointing to default locations handled by ld-linux
        if grep -qE "^${basedir}/(lib|usr/lib)$" <<<"${abspath}" ; then
            log.debug \
                "\tDROPPED [std libdirs]: %s (%s)\n" "${rpath}" "${abspath}"
            continue
        fi

        log.debug "\tKEPT %s (%s)\n" "${rpath}" "${abspath}"

        libdirs+=( "${abspath}" )

    done

    libdirs=( $(utils.list_reduce ${libdirs[@]}) )

    patchelf.update_rpath "${basedir}" "${binary}" ${libdirs[@]}
}
