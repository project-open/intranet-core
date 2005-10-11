# /packages/intranet-core/www/users/nuke.tcl
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
    Try to remove a user completely

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    { return_url "/intranet/users" }
}


db_1row user_full_name "
    select *
    from
	im_projects
    where 
	project_id = :project_id
"

set page_title [_ intranet-core.Nuke_this_project]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
set object_name $project_name
set object_type "project"

set delete_user_link "<a href=\"/acs-admin/users/member-state-change?member_state=banned&[export_url_vars project_id return_url]\">[_ intranet-core.lt_delete_this_user_inst]</a>"
