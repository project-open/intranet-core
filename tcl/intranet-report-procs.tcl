# /packages/intranet-core/tcl/intranet-report-procs.tcl
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

ad_library {
    Definitions for the intranet module

    @author frank.bergmann@project-open.com
}


ad_register_proc GET /intranet/exports/* im_export


ad_proc -public im_export { } {
    Receives requests from /intranet/reports,
    exctracts parameters and calls the right report

} {
    set url "[ns_conn url]"
    set url [im_url_with_query]
    ns_log Notice "intranet_download: url=$url"

    # /intranet/export/1934/export.tcl
    # Using the report_id as selector for various reports
    set path_list [split $url {/}]
    set len [expr [llength $path_list] - 1]

    # skip: +0:/ +1:intranet, +2:export, +3:report_id, +4:...
    set report_id [lindex $path_list 3]
    ns_log Notice "report_id=$report_id"

    set report [im_export_report $report_id]

    im_export_all

    db_release_unused_handles
#    doc_return  200 "application/csv" $report
    doc_return  200 "html/text" "<pre>\n$report\n</pre>\n"
}


ad_proc -public im_export_all { } {
    Exports all reports with IDs >= 100 && < 200
    and saves them to /tmp/.
} {

    db_foreach foreach_report "
select
	v.*
from 
	im_views v
where 
	view_id >= 100
	and view_id < 200
" {
    set report [im_export_report $view_id]
    set stream [open /tmp/$view_name.csv w]
    puts $stream $report
    close $stream
}



}

ad_proc -public im_export_report { report_id } {
    Execute an export report
} {
    set user_id [ad_maybe_redirect_for_registration]
    if {![im_is_user_site_wide_or_intranet_admin $user_id]} {
	ad_return_complaint 1 "<li>You have insufficient permissions to see this page."
	return
    }
    
    # Get the Report SQL
    #
    set rows [db_0or1row get_report_info "
select 
	view_sql as report_sql
from 
	im_views 
where 
	view_id = :report_id
"]
    if {!$rows} {
	ad_return_complaint 1 "<li>Unknown report \#$report_id"
	return
    }


    # Define the column headers and column contents that
    # we want to show:
    #
    set column_sql "
select
        column_name,
        column_render_tcl,
        visible_for
from
        im_view_columns
where
        view_id=:report_id
        and group_id is null
order by
        sort_order"

    set column_headers [list]
    set column_vars [list]
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }

    # Execute the report
    #
    set ctr 0
    set results ""
    db_foreach projects_info_query $report_sql {

        # Append a line of data based on the "column_vars" parameter list
        set row_ctr 0
        foreach column_var $column_vars {
            if {$row_ctr > 0} { append results ", " }
            append results "\""
            set cmd "append results $column_var"
            eval $cmd
            append results "\""
            incr row_ctr
        }
        append results "\n"

        incr ctr
    }

    return $results
}



ad_proc -public im_export_test { report_id } {
    Execute an export report
} {
    set user_id [ad_maybe_redirect_for_registration]
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
    
    lappend column_headers "customer_name"
    lappend column_vars {$customer_name}
    
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
	c.customer_name,
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
        im_customers c
where 
        p.customer_id = c.customer_id
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
	    if {$row_ctr > 0} { append results ", " }
	    append results "\""
	    set cmd "append results $column_var"
	    eval $cmd
	    append results "\""
	    incr row_ctr
	}
	append results "\n"
	
	incr ctr
    }

    return $results
}
