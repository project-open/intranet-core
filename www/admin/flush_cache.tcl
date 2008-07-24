# /packages/intranet-filestorage/www/index.tcl
#
# Copyright (C) 2004 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Flush the permissions cache after adding or removing
    privileges from a user.

    @author frank.bergmann@project-open.com
} {
    { return_url ""}
}

if {"" == $return_url} {
    set return_url "/intranet/admin/"
}

# Remove all permission related entries in the system cache
im_permission_flush

db_release_unused_handles
ad_returnredirect $return_url



