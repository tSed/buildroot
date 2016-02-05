#!/bin/sh

candidate="$1"

cmake=`which $candidate`
if [ ! -x "$cmake" ]; then
	# echo nothing: no suitable cmake found
	exit 1
fi

version=`$cmake --version | head -n1 | cut -d\  -f3`
major=`echo "$version" | cut -d. -f1`
minor=`echo "$version" | cut -d. -f2`

# Versions before 3.0 are affected by the bug described in
# https://git.busybox.net/buildroot/commit/?id=ef2c1970e4bff3be3992014070392b0e6bc28bd2
# and fixed in upstream CMake in version 3.0:
# https://cmake.org/gitweb?p=cmake.git;h=e8b8b37ef6fef094940d3384df5a1d421b9fa568
major_min=3
minor_min=0
if [ $major -gt $major_min ]; then
	echo $cmake
else
	if [ $major -eq $major_min -a $minor -ge $minor_min ]; then
		echo $cmake
	else
		# echo nothing: no suitable cmake found
		exit 1
	fi
fi
