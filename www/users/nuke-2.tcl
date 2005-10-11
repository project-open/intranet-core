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
    ad_return_complaint "You need to have administration rights for this user."
    return
}


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

# if this fails, it will probably be because the installation has 
# added tables that reference the users table


set result [im_user_nuke $user_id]
if {"" != $result} {
    ad_return_error "[_ intranet-core.Failed_to_nuke]" $result
}

set return_to_admin_link "<a href=\"/intranet/users/\">[_ intranet-core.lt_return_to_user_admini]</a>" 

set page_content "[ad_admin_header "[_ intranet-core.Done]"]

<h2>[_ intranet-core.Done]</h2>

<hr>

[_ intranet-core.lt_Weve_nuked_user_user_]

[ad_admin_footer]
"


doc_return  200 text/html $page_content
