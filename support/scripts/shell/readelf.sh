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
#   readelf._filter_elf_regexp
#   readelf.filter_elf
#   readelf.filter_elf_executable
#   readelf.filter_elf_shared_object
#   readelf.is_elf_executable
#   readelf.is_elf_shared_object
#   readelf.get_rpath
#   readelf.get_neededs
#   readelf.needs_rpath
#   readelf.has_rpath
#   readelf.list_sections
#   readelf.has_section
#
# This module is sensitive to the following environment variables:
#   READELF

source.declare_module readelf

# When calling readelf(1) program, the user's locale will be overriden with the
# C locale, so we are sure we can reliably parse its output.
: ${READELF:=readelf}

# readelf._filter_elf_regexp filter_cmd file...
#
# Filters ELF files WRT the given regular extended expression.
# This funtion can take one or several files, or read them from stdin.
#
# filter_cmd : filter command (usually based on grep)
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
            LC_ALL=C ${READELF} -h "${file}" 2>/dev/null |
                grep -qE "${regexp}" ||
                    continue
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
