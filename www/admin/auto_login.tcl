# /packages/intranet-core/www/admin/x_field.tcl
#
# Copyright (C) 2004 Project/Open 
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
    Calculates the "auto_login" (hashed user_id + password) for 
    a user.

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { user_id 0 }
}

if {0 == $user_id} {
    set user_id [ad_get_user_id]
}

set auto_login [im_generate_auto_login -user_id $user_id]

ad_return_complaint 1 "auto_login for user $user_id is '$auto_login'"