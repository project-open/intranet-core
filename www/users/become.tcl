# /packages/intranet-core/www/users/become.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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
    Let authorized users become any user.

    @param user_id
    @author mobin@mit.edu (Usman Y. Mobin)
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/" }
    user_id:integer,notnull
}


# Check the permissions that the current_user has on user_id
set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin
if {!$admin} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_are_not_authorize]"
    ad_script_abort
}

ad_user_login $user_id
ad_returnredirect $return_url
