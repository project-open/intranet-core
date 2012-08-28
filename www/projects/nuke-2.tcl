# /packages/intranet-core/www/projects/nuke-2.tcl
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

    @author frank.bergmann@project-open.com
} {
    { project_id:integer,multiple,notnull ""}
    { return_url ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set page_title [_ intranet-core.Done]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
set current_user_id [ad_maybe_redirect_for_registration]

set results {}
foreach pid $project_id {
    im_project_permissions $current_user_id $pid view read write admin
    if {!$admin} {
	ad_return_complaint 1 "You need to have administration rights for this project."
	ad_script_abort
    }

    lappend results [im_project_nuke $pid]
}

set result [join $results "\n<br>\n"]
set result_len [string length $result]

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------


set return_to_admin_link "<a href=\"/intranet/projects/\">[_ intranet-core.lt_return_to_user_admini]</a>" 

