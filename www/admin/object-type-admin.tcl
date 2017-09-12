# /packages/intranet-core/www/admin/object-type-admin.tcl
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
    Redirect to admin pages for certain object types.
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { object_type "" }
    { url "/intranet/admin/" }
}

switch $object_type {
    im_ticket { set url "/intranet-helpdesk/admin/" }

}


ad_returnredirect $url


