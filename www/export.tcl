# /www/intranet/export.tcl
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
    Export business objects as CSV

    @author frank.bergmann@project-open.com
} {
    { start_idx:integer 0 }
    { how_many "" }
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

if {![im_is_user_site_wide_or_intranet_admin $user_id]} {
    ad_return_complaint 1 "<li>You have insufficient permissions to see this page."
}

# ----------------------------------------------------------
# Define the Report
# ----------------------------------------------------------

set column_headers [list]
set column_vars [list]

lappend column_headers "project_name"
lappend column_vars {$project_name}

lappend column_headers "project_nr"
lappend column_vars {$project_nr}

lappend column_headers "project_path"
lappend column_vars {$project_path}

lappend column_headers "parent_name"
lappend column_vars {$parent_name}

lappend column_headers "company_name"
lappend column_vars {$company_name}

lappend column_headers "project_type"
lappend column_vars {$project_type}

lappend column_headers "project_status"
lappend column_vars {$project_status}

lappend column_headers "description"
lappend column_vars {$description}

lappend column_headers "billing_type"
lappend column_vars {$billing_type}

lappend column_headers "start_date"
lappend column_vars {$start_date_time}

lappend column_headers "end_date"
lappend column_vars {$end_date_time}

lappend column_headers "note"
lappend column_vars {$note}

lappend column_headers "project_lead"
lappend column_vars {$project_lead}

lappend column_headers "supervisor"
lappend column_vars {$supervisor}

lappend column_headers "requires_report_p"
lappend column_vars {$requires_report_p}

lappend column_headers "project_budget"
lappend column_vars {$project_budget}


set sql "
select 
	p.*,
	c.company_name,
	parent_p.project_name as parent_name,
        im_name_from_user_id(p.project_lead_id) as project_lead,
        im_name_from_user_id(p.supervisor_id) as supervisor,
        im_category_from_id(p.project_type_id) as project_type,
        im_category_from_id(p.project_status_id) as project_status,
        im_category_from_id(p.billing_type_id) as billing_type,
        to_char(p.end_date, 'YYYYMMDD HH24:MI') as end_date_time,
        to_char(p.start_date, 'YYYYMMDD HH24:MI') as start_date_time
from 
	im_projects p, 
	im_projects parent_p, 
        im_companies c
where 
        p.company_id = c.company_id
	and p.parent_id = parent_p.project_id
"

# ----------------------------------------------------------
# Execute the report
# ----------------------------------------------------------

set ctr 0
set results ""
db_foreach projects_info_query $sql {

    # Append a line of data based on the "column_vars" parameter list
    set row_ctr 0
    foreach column_var $column_vars {
	if {$row_ctr > 0} { append results "," }
	append results "\""
	set cmd "append results $column_var"
	eval "$cmd"
	append results "\""
	incr row_ctr
    }
    append results "\n"

    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
}

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set page_body "
<pre>
$results
</pre>
"

db_release_unused_handles

doc_return  200 text/html [im_return_template]
