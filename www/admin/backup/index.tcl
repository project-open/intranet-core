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

set context_bar [ad_context_bar $page_title]
set context ""

set menu_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"


# ------------------------------------------------------
# Get the list of objects to backup/restore
# ------------------------------------------------------

set sql "
select
	v.*
from 
	im_views v
where 
	view_id >= 100
	and view_id < 200
"

# Prepare the path for the export
#
if {![file isdirectory $path]} {
    if { [catch {
	ns_log Notice "/bin/mkdir $path"
	exec /bin/mkdir "$path"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\m</pre>"
	return
    }
}

append path "$today/"
if {![file isdirectory $path]} {
    if { [catch {
	ns_log Notice "/bin/mkdir $path"
	exec /bin/mkdir "$path"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\m</pre>"
	return
    }
}

append page_body "<ul>\n"
db_foreach foreach_report $sql {
    append page_body "<li>Exporting $view_name ..."
    set report [im_backup_report $view_id]
    
    if { [catch {
	ns_log Notice "/intranet/admin/backup/backup: writing report to $path"
	
	set stream_name "$path$view_name.csv"
	set stream [open $stream_name w]
	puts $stream $report
	close $stream
	
    } err_msg] } {
	ad_return_complaint 1 "Error writing report to file $stream_name:<br><pre>$err_msg\m</pre>"
	return
    }
}

append page_body "
</ul>
Successfully finished
"


if {"" != $return_url} {
    ad_return_redirect $return_url
} else {
    doc_return  200 text/html [im_return_template]
}

