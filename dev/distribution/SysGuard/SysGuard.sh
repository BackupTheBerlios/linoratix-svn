#!/bin/bash

#
# SysGuard
#
# Copyright (C) 2004 by Jan Gehring <jfried@linoratix.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
 
#function _check_package()
#{
#	
#}

function _remove()
{
	$DIALOG --yesno "Do you really want to remove $1" 0 0
	exit $?
}

function _unlink()
{
	$DIALOG --yesno "Do you really want to unlink $1" 0 0
	exit $?
}

function _rmdir()
{
	$DIALOG --yesno "Do you really want to rmdir $1" 0 0
	exit $?
}

function _rename()
{
	$DIALOG --yesno "Do you really want to rename $1 to $2" 0 0
	exit $?
}


# erstma rausholen ob X laeuft oder nischd
if [ "${DISPLAY}" ]
then
	DIALOG="/usr/bin/env Ldialog"
else
	DIALOG="/usr/bin/env dialog"
fi


case "${1}" in
	remove)
		_remove $2
		;;
	unlink)
		_unlink $2
		;;
	rmdir)
		_rmdir $2
		;;
	rename)
		_rename $2 $3
		;;
	*)
		echo "Usage: $0 <action> <file1> [<file2> ...]"
esac

