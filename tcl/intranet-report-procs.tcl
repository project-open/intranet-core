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


ad_proc -public im_export_version_nr { } {
    Returns a version number

} {
    return "0.5"
}


ad_proc -public im_export_accepted_version_nr { version } {
    Returns "" if the version of the import file is accepted
    or an error message otherwise.
} {
    switch $version {
	"0.5" { return "" }
	default { return "Unknown backup dump version '$version'<br>" }
    }
}



ad_proc -public im_export { } {
    Receives requests from /intranet/reports,
    exctracts parameters and calls the right report

} {
    im_export_all

    im_import_users "/tmp/im_users.csv"
    im_import_offices "/tmp/im_offices.csv"
    im_import_office_members "/tmp/im_office_members.csv"
    im_import_customers "/tmp/im_customers.csv"
    im_import_customer_members "/tmp/im_customer_members.csv"
    im_import_projects "/tmp/im_projects.csv"
    im_import_project_members "/tmp/im_project_members.csv"
    im_import_freelancers "/tmp/im_freelancers.csv"
    im_import_freelance_skills "/tmp/im_freelance_skills.csv"

    ad_return_complaint 1 "Successfully Parsed"
    return

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

    db_release_unused_handles
#    doc_return  200 "application/csv" $report
    doc_return  200 "text/html" "<pre>\n$report\n</pre>\n"
}


ad_proc -public im_export_all { } {
    Exports all reports with IDs >= 100 && < 200
    and saves them to /tmp/.
} {

    set sql "
select
	v.*
from 
	im_views v
where 
	view_id >= 100
	and view_id < 200"

    db_foreach foreach_report $sql {
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
    set separator ";"

    if {![im_is_user_site_wide_or_intranet_admin $user_id]} {
	ad_return_complaint 1 "<li>You have insufficient permissions to see this page."
	return
    }

    # Get the Report SQL
    #
    set rows [db_0or1row get_report_info "
select 
	view_sql as report_sql,
	view_name
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
    set header ""
    set row_ctr 0
    db_foreach column_list_sql $column_sql {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"

	if {$row_ctr > 0} { append header $separator }
	append header "\"$column_name\""
	incr row_ctr
    }

    # Execute the report
    #
    set ctr 0
    set results ""
    db_foreach projects_info_query $report_sql {

        # Append a line of data based on the "column_vars" parameter list
        set row_ctr 0
        foreach column_var $column_vars {
            if {$row_ctr > 0} { append results $separator }
            append results "\""
            set cmd "append results $column_var"
            eval $cmd
            append results "\""
            incr row_ctr
        }
        append results "\n"

        incr ctr
    }

    set version "Project/Open [im_export_version_nr] $view_name"

    return "$version\n$header\n$results\n"
}




ad_proc -public im_import_customers { filename } {
    Import the customers file
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_customers"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	set manager_id [db_string manager "select party_id from parties where email=:manager_email" -default ""]
	set accounting_contact_id [db_string accounting_contact "select party_id from parties where email=:accounting_contact_email" -default ""]
	set primary_contact_id [db_string primary_contact "select party_id from parties where email=:primary_contact_email" -default ""]


	set customer_type_id [db_string customer_type "select category_id from im_categories where category=:customer_type and category_type='Intranet Customer Type'" -default ""]
	set customer_status_id [db_string customer_status "select category_id from im_categories where category=:customer_status and category_type='Intranet Customer Status'" -default ""]
	set crm_status_id [db_string crm_status "select category_id from im_categories where category=:crm_status and category_type='Intranet Customer CRM Status'" -default ""]

	set annual_revenue_id [db_string annual_revenue "select category_id from im_categories where category=:annual_revenue and category_type='Intranet Annual Revenue'" -default ""]


	set main_office_id [db_string main_office "select office_id from im_offices where office_name=:main_office_name" -default ""]
	set customer_id [db_string customer "select customer_id from im_customers where customer_name=:customer_name" -default 0]


	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_customer_sql "
DECLARE
    v_customer_id	integer;
BEGIN
    v_customer_id := im_customer.new(
	customer_name	=> :customer_name,
	customer_path	=> :customer_path,
	main_office_id	=> :main_office_id	
    );
END;
"

	set update_customer_sql "
UPDATE im_customers 
SET
	deleted_p=:deleted_p, 
	customer_status_id=:customer_status_id, 
	customer_type_id=:customer_type_id, 
	note=:note, 
	referral_source=:referral_source, 
	annual_revenue_id=:annual_revenue_id, 
	status_modification_date=sysdate, 
	old_customer_status_id='', 
	billable_p=:billable_p, 
	site_concept=:site_concept, 
	manager_id=:manager_id,
	contract_value=:contract_value, 
	start_date=sysdate, 
	primary_contact_id=:primary_contact_id, 
	main_office_id=:main_office_id, 
	vat_number=:vat_number
WHERE 
	customer_name = :customer_name"


	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "customer_name	$customer_name"
	ns_log Notice "customer_path	$customer_path"
	ns_log Notice "main_office_id	$main_office_id"	


	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    if {0 == $customer_id} {
		# The customer doesn't exist yet:
		db_dml customer_create $create_customer_sql
	    }
	    db_dml update_customer_sql $update_customer_sql
	    
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading customers:<br>
            $err_msg"
	    return
	}
    }
}





ad_proc -public im_import_offices { filename } {
    Import the offices file
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_offices"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	set office_type_id [db_string office_type "select category_id from im_categories where category=:office_type and category_type='Intranet Office Type'" -default ""]
	set office_status_id [db_string office_status "select category_id from im_categories where category=:office_status and category_type='Intranet Office Status'" -default ""]
	set contact_person_id [db_string contact_person "select party_id from parties where email=:contact_person_email" -default ""]

	set office_id [db_string contact_person "select office_id from im_offices where office_name=:office_name" -default 0]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_office_sql "
DECLARE
    v_office_id	integer;
BEGIN
    v_office_id := im_office.new(
	office_name	=> :office_name,
	office_path	=> :office_path
    );
END;
"

	set update_office_sql "
UPDATE im_offices 
SET
	office_path=:office_path,
	office_status_id=:office_status_id, 
	office_type_id=:office_type_id, 
	public_p=:public_p, 
	phone=:phone,
	fax=:fax,
	address_line1=:address_line1,
	address_line2=:address_line2,
	address_city=:address_city,
	address_state=:address_state,
	address_postal_code=:address_postal_code,
	address_country_code=:address_country_code,
	contact_person_id=:contact_person_id,
	landlord=:landlord,
	security=:security,
	note=:note
WHERE 
	office_name = :office_name"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "office_name	$office_name"
	ns_log Notice "office_path	$office_path"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    if {0 == $office_id} {
		# The office doesn't exist yet:
		db_dml office_create $create_office_sql
	    }
	    db_dml update_office_sql $update_office_sql
	    
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading offices:<br>
            $err_msg"
	    return
	}
    }
}





ad_proc -public im_import_projects { filename } {
    Import the projects file
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_projects"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	set project_lead_id [db_string manager "select party_id from parties where email=:project_lead_email" -default ""]
	set supervisor_id [db_string supervisor "select party_id from parties where email=:supervisor_email" -default ""]


	set project_type_id [db_string project_type "select category_id from im_categories where category=:project_type and category_type='Intranet Project Type'" -default ""]
	set project_status_id [db_string project_status "select category_id from im_categories where category=:project_status and category_type='Intranet Project Status'" -default ""]
	set billing_type_id [db_string billing_type "select category_id from im_categories where category=:billing_type and category_type='Intranet Billing Type'" -default ""]

	set customer_id [db_string customer "select customer_id from im_customers where customer_name=:customer_name" -default ""]
	set project_id [db_string project "select project_id from im_projects where project_name=:project_name" -default 0]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_project_sql "
DECLARE
    v_project_id	integer;
BEGIN
    v_project_id := im_project.new(
	project_name	=> :project_name,
	project_nr	=> :project_nr,
	project_path	=> :project_path,
	customer_id	=> :customer_id
    );
END;"

	set update_project_sql "
UPDATE im_projects
SET
	project_name		= :project_name,
	project_nr		= :project_nr,
	project_path		= :project_path,
	customer_id		= :customer_id,
	parent_id		= null,
	project_type_id		= :project_type_id,
	project_status_id	= :project_status_id,
	description		= :description,
	billing_type_id		= :billing_type_id,
	start_date		= to_date(:start_date, 'YYYYMMDD HH24:MI'),
	end_date		= to_date(:end_date, 'YYYYMMDD HH24:MI'),
	note			= :note,
	project_lead_id		= :project_lead_id,
	supervisor_id		= :supervisor_id,
	requires_report_p	= :requires_report_p,
	project_budget		= :project_budget
WHERE
	project_name = :project_name"


	# -------------------------------------------------------
	# Debugging
	#
	ns_log Notice "project_name	$project_name"
	ns_log Notice "project_nr	$project_nr"
	ns_log Notice "project_path	$project_path"
	ns_log Notice "customer_id	$customer_id"
	ns_log Notice "parent_name	$parent_name"


	# ------------------------------------------------------
	# Store the project hierarchy in an array.
	# We need to set the hierarchy after all projects
	# have entered into the system.
	set parent($project_id) $parent_name


	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    if {0 == $project_id} {
		# The project doesn't exist yet:
		db_dml project_create $create_project_sql
	    }
	    db_dml update_project_sql $update_project_sql
	    
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading projects:<br>$err_msg"
	    return
	}

    }

    # Now we've got all projects in the DB so that we can
    # establish the project hierarchy.

    foreach project_id [array names parent] {

	set parent_id [db_string parent "select project_id from im_projects where project_name=:parent_name" -default ""]
	
	set update_sql "
UPDATE im_projects
SET
	parent_id = :parent_id
WHERE
	project_id = :project_id"

	db_dml update_parent $update_sql
    }

}








ad_proc -public im_import_customer_members { filename } {
    Import the users associated with customers
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_customer_members"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set object_id [db_string customer "select customer_id from im_customers where customer_name=:customer_name" -default ""]
	set user_id [db_string user "select party_id from parties where email=:user_email" -default ""]
	set object_role_id [db_string role "select category_id from im_categories where category=:role and category_type='Intranet Biz Object Role'" -default ""]


	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_member_sql "
DECLARE
    v_rel_id	integer;
BEGIN
    v_rel_id := im_biz_object_member.new(
	object_id	=> :object_id,
	user_id		=> :user_id,
	object_role_id	=> :object_role_id
    );
END;"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "object_id	$object_id"
	ns_log Notice "user_id		$user_id"
	ns_log Notice "object_role_id	$object_role_id"


	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string count_members "select count(*) from acs_rels where object_id_one=:object_id and object_id_two=:user_id"]
	    if {!$count} {
		db_dml create_member $create_member_sql
	    }
	    
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading customer members:<br>
            $err_msg"
	    return
	}
    }
}







ad_proc -public im_import_project_members { filename } {
    Import the users associated with projects
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_project_members"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set object_id [db_string project "select project_id from im_projects where project_name=:project_name" -default ""]
	set user_id [db_string user "select party_id from parties where email=:user_email" -default ""]
	set object_role_id [db_string role "select category_id from im_categories where category=:role and category_type='Intranet Biz Object Role'" -default ""]


	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_member_sql "
DECLARE
    v_rel_id	integer;
BEGIN
    v_rel_id := im_biz_object_member.new(
	object_id	=> :object_id,
	user_id		=> :user_id,
	object_role_id	=> :object_role_id
    );
END;"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "object_id	$object_id"
	ns_log Notice "user_id		$user_id"
	ns_log Notice "object_role_id	$object_role_id"


	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string count_members "select count(*) from acs_rels where object_id_one=:object_id and object_id_two=:user_id"]
	    if {!$count} {
		db_dml create_member $create_member_sql
	    }
	    
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading project members:<br>
            $err_msg"
	    return
	}
    }
}







ad_proc -public im_import_office_members { filename } {
    Import the users associated with offices
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_office_members"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set object_id [db_string office "select office_id from im_offices where office_name=:office_name" -default ""]
	set user_id [db_string user "select party_id from parties where email=:user_email" -default ""]
	set object_role_id [db_string role "select category_id from im_categories where category=:role and category_type='Intranet Biz Object Role'" -default ""]


	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_member_sql "
DECLARE
    v_rel_id	integer;
BEGIN
    v_rel_id := im_biz_object_member.new(
	object_id	=> :object_id,
	user_id		=> :user_id,
	object_role_id	=> :object_role_id
    );
END;"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "object_id	$object_id"
	ns_log Notice "user_id		$user_id"
	ns_log Notice "object_role_id	$object_role_id"


	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string count_members "select count(*) from acs_rels where object_id_one=:object_id and object_id_two=:user_id"]
	    if {!$count} {
		db_dml create_member $create_member_sql
	    }
	    
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading office members:<br>
            $err_msg"
	    return
	}
    }
}



ad_proc -public im_import_freelancers { filename } {
    Import the freelancer information
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_freelancers"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set user_id [db_string user "select party_id from parties where email=:user_email" -default ""]
	set payment_method_id [db_string payment_method "select category_id from im_categories where category=:payment_method" -default ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_sql "INSERT INTO im_freelancers (user_id) values (:user_id)"
	set update_sql "
UPDATE im_freelancers
SET
        translation_rate	= :translation_rate,
        editing_rate		= :editing_rate,
        hourly_rate		= :hourly_rate,
        bank_account		= :bank_account,
        bank			= :bank,
        payment_method_id	= :payment_method_id,
        note			= :note,
        private_note		= :private_note
WHERE
	user_id=:user_id
"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "user_id			$user_id"
	ns_log Notice "payment_method_id	$payment_method_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string count_members "select count(*) from im_freelancers where user_id=:user_id"]
	    if {!$count} {
		db_dml create_member $create_sql
	    }
	    db_dml update_freelancer $update_sql
	    
	 } err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading freelancers:<br> $err_msg"
	    return
	}
    }
}




ad_proc -public im_import_freelance_skills { filename } {
    Import the freelance skill database
} {
    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_freelance_skills"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set user_id [db_string user "select party_id from parties where email=:user_email" -default ""]
	set skill_id [db_string office "select category_id from im_categories where category=:skill" -default ""]
	set skill_type_id [db_string office "select category_id from im_categories where category=:skill_type" -default ""]
	set claimed_experience_id [db_string office "select category_id from im_categories where category=:claimed_experience" -default ""]
	set confirmed_experience_id [db_string office "select category_id from im_categories where category=:confirmed_experience" -default ""]
	set confirmation_user_id [db_string user "select party_id from parties where email=:confirmation_user_email" -default ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_sql "
INSERT INTO im_freelance_skills (
	user_id, skill_id, skill_type_id,
	claimed_experience_id, confirmed_experience_id,
	confirmation_user_id, confirmation_date
) values (
	:user_id, :skill_id, :skill_type_id,
	:claimed_experience_id, :confirmed_experience_id,
	:confirmation_user_id, :confirmation_date
)"	

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "user_id		$user_id"
	ns_log Notice "skill_id		$skill_id"
	ns_log Notice "skill_type_id	$skill_type_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string freelance_skill_count "select count(*) from im_freelance_skills where user_id=:user_id and skill_id=:skill_id and skill_type_id=:skill_type_id"]
	    if {!$count} {
		db_dml create_freelance_skill $create_sql
	    }
	    
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading freelance_skills:<br>
            $err_msg"
            return
	}
    }
}






ad_proc -public im_import_users { filename } {
    Import the user information
} {
    ns_log Notice "im_import_users $filename"

    if {![file readable $filename]} {
	ad_return_complaint 1 "Unable to read file '$filename'"
	return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified export version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_export_accepted_version_nr $csv_version]
    if {![string equal $csv_system "Project/Open"]} { 
	append err_msg "'$csv_system' invalid backup dump<br>" 
    }
    if {![string equal $csv_table "im_users"]} { 
	append err_msg "Invalid backup table: '$csv_table'<br>" 
    }
    if {"" != $err_msg} {
	ad_return_complaint 1 "<li>Error reading '$filename': <br>$err_msg"
	return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
        ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Extract variables from the CSV file
	#

	for {set j 0} {$j < $csv_header_len} {incr j} {

	    set var_name [string trim [lindex $csv_header_fields $j]]
	    set var_value [string trim [lindex $csv_line_fields $j]]

	    # Skip empty columns caused by double quote separation
	    if {"" == $var_name || [string equal $var_name ";"]} { 
		continue 
	    }

	    set cmd "set $var_name \"$var_value\""
	    ns_log Notice "cmd=$cmd"
	    set result [eval $cmd]
	}
	
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	if {"" == $email} {
	    # Special case for users without email
	    ad_return_complaint 1 "<li>Found a user without email address:<br>
            User '$first_names $last_name' doesn't have an email address
            and thus cannot be inserted into the database."
	    return
	}

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_user_sql "
DECLARE
    v_user_id	integer;
BEGIN
    v_user_id := acs_user.new(
	username      => :username,
	email         => :email,
	first_names   => :first_names,
	last_name     => :last_name,
	password      => :password,
	salt          => :salt
    );

    INSERT INTO users_contact (user_id) 
    VALUES (v_user_id);
END;"

	set update_users_sql "
UPDATE
	users
SET
	username	= :username,
	screen_name	= :screen_name,
	password	= :password,
	salt		= :salt,
        password_question = :password_question,
        password_answer	= :password_answer
WHERE
	user_id=:user_id
"

	set update_parties_sql "
UPDATE
	parties
SET
	url=:url
WHERE
	party_id=:user_id
"

	set update_persons_sql "
UPDATE
	persons
SET
	first_names	= :first_names,
	last_name	= :last_name
WHERE
	person_id=:user_id
"	

	set update_users_contact_sql "
UPDATE
	users_contact
SET
        home_phone              = :home_phone,
        work_phone              = :work_phone,
        cell_phone              = :cell_phone,
        pager                   = :pager,
        fax                     = :fax,
        aim_screen_name         = :aim_screen_name,
        msn_screen_name         = :msn_screen_name,
        icq_number              = :icq_number,
        ha_line1                = :ha_line1,
        ha_line2                = :ha_line2,
        ha_city                 = :ha_city,
        ha_state                = :ha_state,
        ha_postal_code          = :ha_postal_code,
        ha_country_code         = :ha_country_code,
        wa_line1                = :wa_line1,
        wa_line2                = :wa_line2,
        wa_city                 = :wa_city,
        wa_state                = :wa_state,
        wa_postal_code          = :wa_postal_code,
        wa_country_code         = :wa_country_code,
        note                    = :note
WHERE
	user_id=:user_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	set count [db_string user "select count(*) from parties where email=:email"]
        if {!$count} {
	    if { [catch {
		db_dml create_user $create_user_sql
	    } err_msg] } {
	        ad_return_complaint 1 "<li>Error loading users 1:<br>$err_msg"
	        return
	    }
	}

	set user_id [db_string user "select party_id from parties where email=:email"]

	if { [catch {
	    db_dml update_users $update_users_sql
	    db_dml update_parties $update_parties_sql
	    db_dml update_persons $update_persons_sql
	    db_dml update_users_contact $update_users_contact_sql
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    ad_return_complaint 1 "<li>Error loading users 2:<br>$err_msg"
	    return
	}


    }
}





