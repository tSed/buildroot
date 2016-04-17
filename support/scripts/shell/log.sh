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

# Logging helpers
#
# This module defines the following functions:
#   log.trace
#   log.debug
#   log.info
#   log.warn
#   log.errorN
#   log.error
#
# This module sets the following variables:
#   my_name
#
# This module is sensitive to the following environment variables:
#   DEBUG

source.declare_module log

# Debug level:
# - 0 or empty: only show errors
# - 1         : show errors and warnings
# - 2         : show errors, warnings, and info
# - 3         : show errors, warnings, info and debug
: ${SHELL_DEBUG:=0}

# Low level utility function
log.trace()  {
    local level="${1}" msg="${2}"
    shift 2
    printf "[%-5s] %s: ${msg}" "${level:0:5}" "${my_name}" "${@}"
}

# Public logging functions
log.debug()  { :; }
[ ${SHELL_DEBUG} -lt 3 ] || log.debug() { log.trace DEBUG "${@}" >&2; }
log.info()   { :; }
[ ${SHELL_DEBUG} -lt 2 ] || log.info()  { log.trace INFO "${@}" >&2; }
log.warn()   { :; }
[ ${SHELL_DEBUG} -lt 1 ] || log.warn()  { log.trace WARN "${@}" >&2; }
log.errorN() { local ret="${1}" ; shift ; log.trace ERROR "${@}" ; return ${ret} ; }
log.error()  { log.errorN 1 "${@}"; }

# Program name
my_name="${0##*/}"

