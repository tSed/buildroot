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

# Source helpers
#
# This module defines the following functions:
#   source.declare_module
#   source.load_module
#
# This module is sensitive to the following environment variables:
#   TOPDIR

# Assuming the script sourcing this file is in support/scripts/
: ${TOPDIR:=$(readlink -f "${0}" | sed -re 's:(/[^/]+){3}$::')}

# source.declare_module module_name
#
# Declare a shell module.
# Set the variable '_source_${module_name}'.
# Should be called once per module, in the global scope.
#
# module_name : Module name (allowed char.: [_a-zA-Z0-9])
source.declare_module() {
    local module_name="${1}"
    # use printf from bash to set the variable in the environment:
    printf -v "_source_${module_name}" "%s" "${module_name}"
}

# source.load_module module_name
#
# Load the given shell module, making available all functions declared
# in it, ensuring it is not reloaded if it already is.
# Should be called in the global scope.
# Need the TOPDIR environment variable.
#
# param module_name: Module name
source.load_module() {
    local module_name="${1}"
    local loaded="loaded=\${_source_${module_name}}"
    eval "${loaded}"
    local module_file="${TOPDIR}/support/scripts/shell/${module_name}.sh"

    if [ ! -f "${module_file}" ] ; then
        cat <<EOF >&2
error:  Could load module '${module_name}',
        ${module_file} does not exists.

        Maybe TOPDIR does not point to Buildroot's '\$(TOPDIR)'.

        Or this script '${0##*/}' is most not installed in Buildroot's
        '\$(TOPDIR)/support/scripts' directory.

        You can fix this by:
        - either installing '${0##*/}' in the support/scripts/ directory;
        - or setting the TOPDIR variable in the '${0##*/}' script, before
          sourcing anything.
EOF
        exit 1
    fi

    test -n "${loaded}" || source "${module_file}"
}

source.declare_module source
