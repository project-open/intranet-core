# /packages/intranet-core/www/users/nuke-2.tcl
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

ad_page_contract {
    Remove a user from the system completely

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin

if {!$admin} {
    ad_return_complaint 1 "You need to have administration rights for this user."
    return
}


db_1row user_full_name "
    select
	im_name_from_user_id(user_id) as user_name
    from
        cc_users
    where
        user_id = :user_id
"

set return_to_admin_link "/intranet/users/"

set page_title "[lang::message::lookup "" intranet-core.Nuke "Nuke"] $user_name"
set context_bar [im_context_bar [list $return_to_admin_link "[_ intranet-core.Users]"] $page_title]
set object_name $user_name
set object_type "user"


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

# if this fails, it will probably be because the installation has 
# added tables that reference the users table


set result [im_user_nuke $user_id]
if {"" != $result} {
    ad_return_error "[_ intranet-core.Failed_to_nuke]" $result
}

