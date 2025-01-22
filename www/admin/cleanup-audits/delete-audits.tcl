# /packages/intranet-core/www/admin/cleanup-audits/delete-audits.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Delete big tables in the DB
    @author frank.bergmann@project-open.com
} {
    object_type
    return_url
    { limit 1000 }
    { iterations 10 }
}


# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Delete Audits"
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------
# 
# ------------------------------------------------------

# Write out HTTP header
im_report_write_http_headers -output_format html -report_name "delete-audits"

ns_write "
	[im_header $page_title]
	[im_navbar admin]
"
ns_write "<h1>$page_title</h1>\n"

# ------------------------------------------------------
# 
# ------------------------------------------------------

set flush ""
for {set i 0} {$i < 100} {incr i} { set flush "$flush\n\n\n\n" }

set audit_ids [list 0]
set cnt 0
while {0 != [llength $audit_ids] && $cnt < $iterations} {

    db_dml acs_object_fk "update acs_objects set last_audit_id = null where last_audit_id is not null and last_audit_id in ([join $audit_ids ","])"
    db_dml im_audits_fk "update im_audits set audit_last_id = null where audit_last_id is not null and audit_last_id in ([join $audit_ids ","])"
    db_dml del "delete from im_audits where audit_id in ([join $audit_ids ","])"

    if {$cnt > 0} {
	ns_write " deleted</li>\n"
	ns_write "\n"
    }
    incr cnt

    ns_write "<li>Deleting $limit ... \n"

    set audit_ids [db_list audit_ids "
		select	audit_id
		from	im_audits a,
			acs_objects o
		where	a.audit_object_id = o.object_id and
			o.object_type = :object_type
		order by audit_id     -- oldest ones first
		LIMIT $limit
    "]

}

ns_write " deleted</li>\n"
ns_write "\n"


ns_write "<br>&nbsp;<br><b><a href=$return_url>Return to previous page</a></b>\n"
ns_write [im_footer]


