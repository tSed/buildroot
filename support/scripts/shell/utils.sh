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

# Miscellaneous helpers
#
# This module defines the following functions:
#   utils.list_has
#   utils.list_reduce
#   utils.assert_absolute_canonical_path

if test ${0##*/} = "utils.sh" ; then
    TOPDIR=$(readlink -f "$(dirname "${0}")/../../..")
    source "${TOPDIR}/support/scripts/shell/source.sh"
fi
source.declare_module utils

# utils.list_has value list_items...
#
# Returns 0 if $list_items contains $value, returns 1 otherwise.
#
# value      : item to be checked if it is in the list
# list_items : list of items
utils.list_has() {
    local key=$1
    shift
    for val in $@ ; do
        if test "$val" = "$key" ; then
            return 0
        fi
    done
    return 1
}

# utils.list_reduce input_list
#
# Prints the $input_list list with duplicated items removed.
# Order is preserved, WRT the first occurence of duplicated items.
#
# input_list : list of items
utils.list_reduce() {
    local -a lout # return list
    local i

    for i in ${@} ; do
        if utils.list_has "${i}" ${lout[@]} ; then
            continue
        fi
        lout+=( "${i}" )
    done

    echo ${lout[@]}
}

# utils.assert_absolute_canonical_path path
#
# Returns 0 if 'path' is the absolute canonical path, returns non-0
# otherwise.
#
# If the test failed, an error message will be issued to stderr.
#
# path : path to be tested
utils.assert_absolute_canonical_path() {
    test "$(readlink -f "${1}")" = "${1}" ||
        log.error "%s is not the absolute canonical path.\n" "${1}" >&2
}

if test ${0##*/} = "utils.sh" ; then
unit_tests() {
    set -e
    printf "Unit tests - Module: %s\n\n" "${0##*/}"

    local -a L TESTS_BOOL_FUNCS TESTS_BOOL_INPUTS TESTS_ALTER_FUNCS
    local tmpdir="$(mktemp -d)"
    local SYSROOT_PATH="${tmpdir}/path/to/some/toolchain/$(gcc -dumpmachine)/sysroot"

    # setup
    mkdir -p "${SYSROOT_PATH}"

    L=( aba ab ba a b abb aa ab aba b aab )
    TESTS_BOOL_INPUTS=( a z )
    TESTS_BOOL_FUNCS=( \
        utils.list_has \
    )
    TESTS_ALTER_FUNCS=( \
        utils.list_reduce: \
        utils.guess_gnu_target_name:"${SYSROOT_PATH}" \
    )

    printf "inputs:\n"
    printf "  L = [ %s ]\n" "${L[*]}"
    printf "\n"

    local i t f a

    for f in ${TESTS_BOOL_FUNCS[@]} ; do
        printf "%s:\n" "${f}"

        for i in ${TESTS_BOOL_INPUTS[@]} ; do
            printf "  %-30s : " "L ${f#*.} '${i}' ?"
            ${f} "${i}" ${L[@]} && printf "yes" || printf "no"
            printf "\n"
        done
        printf "\n"
    done

    for t in ${TESTS_ALTER_FUNCS[@]} ; do
        f="${t%:*}"
        a=( "${t#*:}" )
        if test -z "${a[0]}" ; then
            a=( ${L[@]} )
        fi
        printf "%s:\n" "${f}"
        printf "  input  : '%s'\n" "${a[*]}"
        printf "  output : '%s'\n" "$( ${f} ${a[*]} )"
        printf "\n"
    done

    # tear down
    rm -rf "${tmpdir}"
}

unit_tests
fi
