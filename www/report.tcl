# /packages/intranet-core/www/export.tcl
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
    { start_idx:integer "1" }
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
lappend column_headers "Project #"
lappend column_vars {"<A HREF='/intranet/projects/view?project_id=$project_id'>" $project_nr "</A>"}
lappend column_headers "Project Name"
lappend column_vars {$project_name}
lappend column_headers "Delivery Date"
lappend column_vars {"$end_date $end_date_time"}
lappend column_headers "Status"
lappend column_vars {$project_status}

set sql "
select 
	p.*,
	c.company_name,
        im_name_from_user_id(p.project_lead_id) as lead_name, 
        im_category_from_id(p.project_type_id) as project_type, 
        im_category_from_id(p.project_status_id) as project_status,
        im_proj_url_from_type(p.project_id, 'website') as url,
        to_char(end_date, 'HH24:MI') as end_date_time
from 
	im_projects p, 
        im_companies c
where 
        p.company_id = c.company_id
"

# ----------------------------------------------------------
# Execute the report
# ----------------------------------------------------------

set ctr 0
set results ""
db_foreach projects_info_query $sql {

    # Append a line of data based on the "column_vars" parameter list
    append results "\n<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append results "\n\t<td valign=top>"
	set cmd "append results $column_var"
	eval "$cmd"
	append results "\n\t</td>"
    }
    append results "\n</tr>\n"

    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
}

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set page_body "
<table width=100% cellpadding=2 cellspacing=2 border=0>
$results
</table>"

db_release_unused_handles

doc_return  200 text/html [im_return_template]
