# /packages/intranet-core/www/admin/menus/index.tcl
#
# Copyright (C) 2004 Project/Open
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
    Show the permissions for all menus in the system

    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/menus/index" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Backup & Restore"
set context_bar [im_context_bar $page_title]
set context ""
set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

set menu_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# ------------------------------------------------------
# Get the list of backup sets for restore
# ------------------------------------------------------

# Get the list of all backup sets under backup_path
set backup_path [im_backup_path]
set file_list [exec $find_cmd $backup_path -type d -maxdepth 1 -mindepth 1]

set backup_sets_html "<ul>\n"

foreach file $file_list {

    append backup_sets_html "<li>Restore from: <A href=restore?path=[ns_urlencode $file]>$file</a></li>\n"
}

append backup_sets_html "
</ul>
"



set sql "
select
        v.*
from
        im_views v
where
        view_id >= 100
        and view_id < 200
"

