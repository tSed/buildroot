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

# SDK helpers
#
# This module defines the following functions:
#   sdk.compute_relative_path
#   sdk.compute_rpath
#   sdk.check_host_leaks
#
# This module is sensitive to the following environment variables:
#   READELF

source.declare_module sdk

source.load_module utils
source.load_module readelf

# sdk.compute_relative_path basedir path start
#
# Computes and prints the relative path between $start and $path within $basedir.
#
# basedir : absolute path of the tree in which the $path and $start must be
# path    : destination absolute path
# start   : origin absolute path
sdk.compute_relative_path() {
    local basedir="${1}"
    local path="${2}"
    local start="${3}"
    # sanity checks: make sure $path and $start starts with $basedir
    grep -q "^${basedir}" <<<"${path}" || return 1
    grep -q "^${basedir}" <<<"${start}" || return 1
    local i
    local backward="${start#${basedir}}"
    local relative=()
    for i in ${backward//\// } ; do
        # don't need to check for empty items they are already discarded
        test "${i}" != '.' || continue
        relative+=( ".." )
    done
    relative+=( ${path#${basedir}} )
    sed -r -e 's:[ /]+:/:g' <<<"${relative[@]}"
}

# sdk.compute_rpath basedir bindir libdirs...
#
# Computes and prints the list of RPATH.
#
# basedir : absolute path of the tree in which the $bindir and $libdirs must be
# bindir  : binary directory absolute path
# libdirs : list of library directories (absolute paths)
sdk.compute_rpath() {
    local basedir="${1}"
    local bindir="${2}"
    shift 2
    local libdirs=( ${@} )
    local rpath=()
    for libdir in ${libdirs[@]} ; do
        rpath+=( "\$ORIGIN/$(sdk.compute_relative_path "${basedir}" "${libdir}" "${bindir}")" )
    done
    sed -e 's/ /:/g' <<<"${rpath[@]}"
}
