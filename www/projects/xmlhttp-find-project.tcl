# /packages/intranet-core/www/offices/xmlhttp-find-project.tcl
#
# Copyright (C) 2009 ]project-open[
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
    Returns a komma separated key-value list of offices per company.
    @param company_id The company
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    user_id:notnull,integer
    search_string:optional
    { auto_login "" }
}

# Check the auto_login token
set valid_login [im_valid_auto_login_p -check_user_requires_manual_login_p 0 -user_id $user_id -auto_login $auto_login]
if {!$valid_login} { 

    # Let the SysAdmin know what's going on here...
    im_security_alert \
	-location "xmlhttp-project-list.tcl" \
	-message "Invalid authentication" \
	-value "user_id=$user_id, auto_login=$auto_login" \
	-severity "Hard"

    doc_return 200 "text/plain" "0,Error: Invalid Authentication for user $user_id"
    ad_script_abort
} 

	# ---------------------------------------------------------------
	# Generate SQL Query

	set project_status_id [im_project_status_open] }
        set order_by_clause  [parameter::get_from_package_key -package_key "intranet-core" -parameter "HomeProjectListSortClause" -default "project_nr DESC"]

	# Project Status restriction
	set project_status_restriction ""
	if {0 != $project_status_id} {
		set project_status_restriction "and p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
	}

	# Project Type restriction
	set project_type_restriction ""
	if {0 != $project_type_id} {
		set project_type_restriction "and p.project_type_id in ([join [im_sub_categories $project_type_id] ","])"
	}

	set perm_sql "
	        (select
        	        p.*
	        from
        	        im_projects p,
                	acs_rels r
	        where
        	        r.object_id_one = p.project_id
                	and r.object_id_two = :user_id
	                and p.parent_id is null
        	        and p.project_status_id not in ([im_project_status_deleted], [im_project_status_closed])
                	$project_status_restriction
	                $project_type_restriction
        	)"

 	set personal_project_query "
        SELECT
                p.*
        FROM
                $perm_sql p,
        WHERE
                $project_status_restriction
                $project_type_restriction
		p.project_name like %:search_string%
        order by 
		$order_by_clause
    "

# ----------------------------------------------------------------

set result ""
db_foreach project $personal_project_query {
    if {"" != $result} { append result ",\n" }
    regsub -all {,} $project_name {} project_name
    append result "$project_id,$project_name"
}

doc_return 200 "text/plain" $result
