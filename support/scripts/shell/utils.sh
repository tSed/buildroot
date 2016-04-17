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
