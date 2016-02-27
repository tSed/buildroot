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

# Readelf helpers
#
# This module defines the following functions:
#   readelf._match_elf_regexp
#   readelf._filter_elf_regexp
#   readelf.filter_elf
#   readelf.filter_elf_executable
#   readelf.filter_elf_shared_object
#   readelf.is_elf_executable
#   readelf.is_elf_shared_object
#   readelf.is_elf_static_library
#   readelf.is_elf_object
#   readelf.get_soname
#   readelf.get_rpath
#   readelf.get_neededs
#   readelf.needs_rpath
#   readelf.has_rpath
#   readelf.list_sections
#   readelf.has_section
#   readelf.string_section
#
# This module is sensitive to the following environment variables:
#   READELF

if test ${0##*/} = "readelf.sh" ; then
    TOPDIR=$(readlink -f "$(dirname "${0}")/../../..")
    source "${TOPDIR}/support/scripts/shell/source.sh"
fi

# When calling readelf(1) program, the user's locale will be overriden with the
# C locale, so we are sure we can reliably parse its output.
: ${READELF:=readelf}

# readelf._match_elf_regexp regexp file
#
# Returns 0 if the ELF file matches the ELF type given in extended regular
# expression, non-0 otherwise.
#
# regexp     : extended regular expression
# file       : list of files to be filtered
#
# environment:
#   READELF: readelf program path
readelf._match_elf_regexp() {
    local regexp="${1}" file="${2}"
    LC_ALL=C ${READELF} -h "${file}" 2>/dev/null | grep -qE "${regexp}"
}

# readelf._filter_elf_regexp regexp file...
#
# Filters ELF files WRT the given extended regular expression.
# This funtion can take one or several files, or read them from stdin.
#
# regexp     : extended regular expression
# file       : list of files to be filtered
#
# environment:
#   READELF: readelf program path
readelf._filter_elf_regexp() {
    local regexp="${1}"
    shift
    local in file
    test ${#} -gt 0 && in='printf "%s\n" "${@}"' || in='dd 2>/dev/null'
    eval "${in}" |
        while read file ; do
            readelf._match_elf_regexp "${regexp}" "${file}" || continue
            printf "%s\n" "${file}"
        done
}

# readelf.filter_elf file...
#
# Filters ELF files; if $file is an ELF file, $file is printed, else it is
# discarded.
# This funtion can take one or several arguments, or read them from stdin.
#
# file : path of file to be filtered
#
# environment:
#   READELF: readelf program path
readelf.filter_elf() {
    readelf._filter_elf_regexp "Class:\s+ELF" "${@}"
}

# readelf.filter_elf_shared_object file...
#
# Filters ELF files; if $file is an ELF file, $file is printed, else it is
# discarded.
# This funtion can take one or several arguments, or read them from stdin.
#
# file : path of file to be filtered
#
# environment:
#   READELF: readelf program path
readelf.filter_elf_shared_object() {
    readelf._filter_elf_regexp "Type:\s+DYN\s\(Shared\sobject\sfile\)" "${@}"
}

# readelf.filter_elf_executable file...
#
# Filters ELF files; if $file is an ELF file, $file is printed, else it is
# discarded.
# This funtion can take one or several arguments, or read them from stdin.
#
# file : path of file to be filtered
#
# environment:
#   READELF: readelf program path
readelf.filter_elf_executable() {
    readelf._filter_elf_regexp "Type:\s+EXEC\s\(Executable\sfile\)" "${@}"
}

# readelf.is_elf_shared_object file
#
# Returns 0 if $file is an ELF file, non-0 otherwise.
#
# file : path of file to be tested
#
# environment:
#   READELF: readelf program path
readelf.is_elf_shared_object() {
    test "$(readelf.filter_elf_shared_object "${1}")" != ""
}

# readelf.is_elf_executable file
#
# Returns 0 if $file is an ELF file, non-0 otherwise.
#
# file : path of file to be tested
#
# environment:
#   READELF: readelf program path
readelf.is_elf_executable() {
    test "$(readelf.filter_elf_executable "${1}")" != ""
}

# readelf.is_elf file
#
# Returns 0 if $file is an ELF file, non-0 otherwise.
#
# file : path of file to be tested
#
# environment:
#   READELF: readelf program path
readelf.is_elf() {
    test "$(readelf.filter_elf "${1}")" != ""
}

# readelf.is_elf_static_library file
#
# Return 0 if $file is a Linux static libraries, i.e. an ar-archive
# containing *.o files.
#
# file : path of file to be tested
readelf.is_elf_static_library() {
    readelf._match_elf_regexp "Type:\s+REL\s\(Relocatable\sfile\)" "${@}" &&
        readelf._match_elf_regexp "^File:\s+\S+\)$" "${@}"
}

# readelf.is_elf_object file
#
# Return 0 if $file is an ELF object file, i.e. a *.o (or *.ko) file.
#
# file : path of file to be tested
readelf.is_elf_object() {
    readelf._match_elf_regexp "Type:\s+REL\s\(Relocatable\sfile\)" "${@}" &&
        ! readelf._match_elf_regexp "^File:\s+\S+\)$" "${@}"
}

# readelf.get_soname file
#
# Return the SONAME of $file.
#
# file : ELF file path
#
# environment:
#   READELF: readelf program path
readelf.get_soname() {
    local file="${1}"
    "${READELF}" --dynamic "${file}" |
        sed -r -e '/.* \(SONAME\) +Library soname: \[(.+)\]$/!d ; s//\1/'
}

# readelf.get_rpath file
#
# Return the unsplitted RPATH/RUNPATH of $file.
#
# To split the returned RPATH string and store them in an array, do:
#
#     paths=( $(readelf.get_rpath "${file}" | sed -e 's/:/ /g') )
#
# file : ELF file path
#
# environment:
#   READELF: readelf program path
readelf.get_rpath() {
    local file="${1}"
    LC_ALL=C "${READELF}" --dynamic "${file}" |
        sed -r -e '/.* \(R(UN)?PATH\) +Library r(un)?path: \[(.+)\]$/!d ; s//\3/'
}

# readelf.get_neededs file
#
# Returns the list of the NEEDED libraries of $file.
#
# file : ELF file path
#
# environment:
#   READELF: readelf program path
readelf.get_neededs() {
    local file="${1}"
    LC_ALL=C "${READELF}" --dynamic "${file}" |
        sed -r -e '/^.* \(NEEDED\) .*Shared library: \[(.+)\]$/!d ; s//\1/'
}

# readelf.needs_rpath file basedir
#
# Returns 0 if $file needs to have RPATH set, 1 otherwise.
#
# file    : path of file to be tested
# basedir : path of the tree in which $basedir/lib and $basedir/usr/lib are
#           checked for belonging to RPATH
#
# environment:
#   READELF: readelf program path
readelf.needs_rpath() {
    local file="${1}"
    local basedir="${2}"
    local lib

    while read lib; do
        [ -e "${basedir}/lib/${lib}" ] && return 0
        [ -e "${basedir}/usr/lib/${lib}" ] && return 0
    done < <(readelf.get_neededs "${file}")
    return 1
}

# readelf.has_rpath file basedir
#
# Returns 0 if $file has RPATH already set to $basedir/lib or $basedir/usr/lib,
# or uses relative RPATH (starting with "$ORIGIN"); returns 1 otherwise.
#
# file    : path of file to be tested
# basedir : path of the tree in which $basedir/lib and $basedir/usr/lib are
#           checked for belonging to RPATH
#
# environment:
#   READELF: readelf program path
readelf.has_rpath() {
    local file="${1}"
    local basedir="${2}"
    local rpath dir

    while read rpath; do
        for dir in ${rpath//:/ }; do
            # Remove duplicate and trailing '/' for proper match
            dir="$(sed -r -e "s:/+:/:g; s:/$::" <<<"${dir}")"
            [ "${dir}" = "${basedir}/lib" ] && return 0
            [ "${dir}" = "${basedir}/usr/lib" ] && return 0
            grep -q '^\$ORIGIN/' <<<"${dir}" && return 0
        done
    done < <(readelf.get_rpath "${file}")

    return 1
}

# readelf.list_sections file
#
# Returns the list of ELF sections in $file.
#
# file    : ELF file path
#
# environment:
#   READELF: readelf program path
readelf.list_sections() {
    local file="${1}"
    LC_ALL=C "${READELF}" --sections "${file}" |
        sed -re '/^  \[ *[0-9]+\] (\S+).*/!d ; s//\1/' |
        sort
}

# readelf.has_section file section
#
# Return 0 if $file has a section named $section
#
# file    : ELF file path
# section : ELF section name
#
# environment:
#   READELF: readelf program path
readelf.has_section() {
    local file="${1}" section_name="${2}"
    readelf.list_sections "${file}" | grep -q "^${section_name}$"
}

# readelf.string_section file section
#
# Return the given $section of $file.
#
# file    : ELF file path
# section : ELF section name
#
# environment:
#   READELF: readelf program path
readelf.string_section() {
    local file="${1}" section="${2}"
    LC_ALL=C "${READELF}" --string-dump "${section}" "${file}" 2>/dev/null
}


if test ${0##*/} = "readelf.sh" ; then
unit_tests() {
    set -e
    printf "Unit tests - Module: %s\n\n" "${0##*/}"

    local ELF_FILES TESTS_IS TESTS_FILTER
    local i t

    # Lists of files used to test is_* and filter_* functions.
    # Update it as you wish.
    ELF_FILES=( \
        /usr/bin/ls \
        /usr/lib/libz.so.1.2.8 \
        /usr/lib/gcc/x86_64-unknown-linux-gnu/5.3.0/crtbeginS.o \
        /media/data/data/src/tmp/br/reloc-sdk/host/usr/lib/libfl.a \
        /tmp/mac80211.ko \
        /usr/lib32/libg.a \
        /usr/lib32/libc-2.22.so \
    )

    TESTS_IS=( \
        readelf.is_elf \
        readelf.is_elf_executable \
        readelf.is_elf_object \
        readelf.is_elf_shared_object \
        readelf.is_elf_static_library \
    )

    TESTS_FILTER=( \
        readelf.filter_elf \
        readelf.filter_elf_executable \
        readelf.filter_elf_object \
        readelf.filter_elf_shared_object \
        readelf.filter_elf_static_library \
    )

    printf "files:\n"
    printf "  %s\n" ${ELF_FILES[@]}
    printf "\n"

    for t in ${TESTS_FILTER[@]} ; do
        printf "%s:\n" "${t}"
        printf "%s\n" ${ELF_FILES[@]} | ${t} | xargs printf "  %s\n"
        printf "\n"
    done

    for i in ${ELF_FILES[@]} ; do
        printf "%s:\n" "${i}"

        for t in ${TESTS_IS[@]} ; do
            printf "  %-30s : " "${t#*.}"
            ${t} "${i}" && printf "yes" || printf "no"
            printf "\n"
        done
        printf "\n"
    done
}

unit_tests
fi
