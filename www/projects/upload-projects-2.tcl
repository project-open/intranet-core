# /packages/intranet-core/www/projects/upload-projects-2.tcl
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
    Read a .csv-file with header titles exactly matching
    the data model and insert the data into "im_projects" and
    "im_timesheet_tasks" tables.
    @author frank.bergmann@project-open.com
} {
    return_url
    upload_file
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Projects CSV"
set page_body "<ul>"
set context_bar [im_context_bar [list "/intranet/cusomers/" "Projects"] $page_title]

set write_projects_all_p [im_permission $current_user_id "edit_projects_all"]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$write_projects_all_p && !$user_admin_p} {
    ad_return_complaint "Insufficient Privileges" "<li>You don't have sufficient privileges to perform this action."
    ad_script_abort
}

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-projects-2.tcl" -value $tmp_filename
if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match project_filename] {
    # couldn't find a match
    set project_filename $upload_file
}

if {[regexp {\.\.} $project_filename]} {
    set error "Filename contains forbidden characters"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}

if {![file readable $tmp_filename]} {
    ad_return_complaint 1 "Unable to read the file '$tmp_filename'. <br>
    Please check the file permissions or contact your system administrator.\n"
    ad_script_abort
}

set csv_files_content [fileutil::cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]

set separator [im_csv_guess_separator $csv_files]
ns_log Notice "upload-projects-2: trying with separator=$separator"
# Split the header into its fields
set csv_header [string trim [lindex $csv_files 0]]
set csv_header_fields [im_csv_split $csv_header $separator]
set csv_header_len [llength $csv_header_fields]
set values_list_of_lists [im_csv_get_values $csv_files_content $separator]


# ------------------------------------------------------------
# Render Result Header

ad_return_top_of_page "
        [im_header]
        [im_navbar]
"


# ------------------------------------------------------------

set cnt 0
foreach csv_line_fields $values_list_of_lists {
    incr cnt
    # Preset values, defined by CSV sheet:

    set billable_units ""
    set billing_type_id ""
    set bt_bug_id ""
    set bt_fix_for_version_id ""
    set bt_found_in_version_id ""
    set bt_project_id ""
    set company_contact_id ""
    set company_id ""
    set company_project_nr ""
    set confirm_date ""
    set corporate_sponsor ""
    set cost_bills_cache ""
    set cost_cache_dirty ""
    set cost_center_id ""
    set cost_delivery_notes_cache ""
    set cost_expense_logged_cache ""
    set cost_expense_planned_cache ""
    set cost_invoices_cache ""
    set cost_purchase_orders_cache ""
    set cost_quotes_cache ""
    set cost_timesheet_logged_cache ""
    set cost_timesheet_planned_cache ""
    set description ""
    set end_date ""
    set expected_quality_id ""
    set final_company ""
    set gantt_project_id ""
    set invoice_id ""
    set material_id ""
    set max_child_sortkey ""
    set milestone_p ""
    set note ""
    set on_track_status_id ""
    set parent_id ""
    set percent_completed ""
    set planned_units ""
    set presales_probability ""
    set presales_value ""
    set priority ""
    set program_id ""
    set project_budget ""
    set project_budget_currency ""
    set project_budget_hours ""
    set project_id ""
    set project_lead_id ""
    set project_name ""
    set project_nr ""
    set project_path ""
    set project_priority_id ""
    set project_risk ""
    set project_status_id ""
    set project_type_id ""
    set release_item_p ""
    set reported_days_cache ""
    set reported_hours_cache ""
    set requires_report_p ""
    set sla_ticket_priority_map ""
    set sort_order ""
    set sort_order ""
    set source_language_id ""
    set start_date ""
    set subject_area_id ""
    set supervisor_id ""
    set task_id ""
    set team_size ""
    set template_p ""
    set trans_project_hours ""
    set trans_project_words ""
    set trans_size ""
    set tree_sortkey ""
    set uom_id ""

    # Transformed variables that need to be dereferenced
    set customer_name ""
    set parent_nrs ""
    set project_status ""
    set project_type ""
    set customer_contact ""
    set on_track_status ""
    set project_manager ""
    set project_priority ""
    set program ""
    set material ""
    set uom ""
    set cost_center_code ""
    set timesheet_task_priority ""
    set source_language ""
    set subject_area ""
    set expected_quality ""
    set customer_project_nr ""

    # -------------------------------------------------------
    # Extract variables from the CSV file
    #

    set var_name_list [list]
    for {set j 0} {$j < $csv_header_len} {incr j} {

	set var_name [string trim [lindex $csv_header_fields $j]]
	if {"" == $var_name} {
	    # No variable name - probably an empty column
	    continue
	}

	set var_name [string tolower $var_name]
        set var_name [string map -nocase {" " "_" "\"" "" "'" "" "/" "_" "-" "_" "\[" "(" "\{" "(" "\}" ")" "\]" ")"} $var_name]
	lappend var_name_list $var_name
	#ns_log notice "upload-projects-2: varname([lindex $csv_header_fields $j]) = $var_name"

	set var_value [string trim [lindex $csv_line_fields $j]]
        set var_value [string map -nocase {"\"" "'" "\[" "(" "\{" "(" "\}" ")" "\]" ")"} $var_value]
	if {[string equal "NULL" $var_value]} { set var_value ""}

	# replace unicode characters by non-accented characters
	# Watch out! Does not work with Latin-1 characters
        set var_name [im_mangle_unicode_accents $var_name]

	set cmd "set $var_name \"$var_value\""
	ns_log Notice "upload-projects-2: cmd=$cmd"
	set result [eval $cmd]
    }


    # ----------------------------------------------------------
    # Massage the data to extract fields

# customer_name
# parent_nrs
# customer_contact
# on_track_status
# project_manager
# project_priority
# program
# material
# uom
# cost_center_code
# timesheet_task_priority
# source_language
# subject_area
# expected_quality
# customer_project_nr

    set company_id [db_string customer "select customer_id from im_companies where lower(company_name) = lower(:customer_name)" -default ""]
    set project_status_id [im_id_from_category $project_status "Intranet Project Status"]
    set project_type_id [im_id_from_category $project_type "Intranet Project Type"]

    set skip_p 0
    foreach var {customer_name project_status project_type} {
	if {"" == [set $var]} {
	    ns_write "<li><b>Found empty variable '$var'.</b>: $var is required, so we have to skip this line."
	    set skip_p 1    
	}
    }
    if {$skip_p} { continue }

    if {"" == $last_name} {
        ns_write "<li>Error: We have found an empty 'Last Name' in line $cnt.<br>
        We can not add users with an empty last name. Please correct the CSV file.<br>
        <pre>$var_name</pre>"
        continue
    }

    # Create a dummy email if there was something set in the parameter:
    if {"" == $e_mail_address && "" != $create_dummy_email} {
        regsub -all { } $first_name "" first_name_nospace
        regsub -all { } $last_name "" last_name_nospace
        set e_mail_address "${first_name_nospace}.${last_name_nospace}${create_dummy_email}"
    }


    # Set project name and path.
    # The path has anything strange replaced by "_".
    set project_name $project
    
    # -------------------------------------------------------
    # Empty project_name
    # => Skip it completely
    if {[empty_string_p $project_name]} {
    	ns_write "<li>'$project_name': Skipping, project name can not be empty.\n"
	continue	
    }
    
    set project_path [im_mangle_user_group_name $project_name]

    set business_country_code [db_string country_code "select iso from country_codes where lower(country_name) = lower(:business_country)" -default ""]
    if {"" == $business_country_code} {
		ns_write "<li>Didn't find '$business_country' in the country database. Please enter manually.\n"
    }

    set office_name "$project_name [_ intranet-core.Main_Office]"
    set office_path "$project_path"

    # Check if the project already exists
    set found_n [db_string project_count "select count(*) from im_projects where lower(project_name) = lower(:project_name)"]

    # -------------------------------------------------------
    # Two or more projects with the same name
    # => Skip it completely
    if {$found_n > 1} {
		ns_write "<li>'$project_name': Skipping, we have found already $found_n projects with this name. Please check and change the names.\n"
		continue
    }

    # -------------------------------------------------------
    # Create a new project if necessary
    #
    if {0 == $found_n} {

	set project_id [im_new_object_id]

	# First create a new main_office:
	set main_office_id [office::new \
		-office_name	$office_name \
		-project_id     $project_id \
		-office_type_id [im_office_type_main] \
		-office_status_id [im_office_status_active] \
		-office_path	$office_path]

	# Now create the project with the new main_office:
	set project_id [project::new \
		-project_id $project_id \
		-project_name	$project_name \
		-project_path	$project_path \
		-main_office_id	$main_office_id \
		-project_type_id $project_type_id_org \
		-project_status_id [im_project_status_active]]	
    } else {

	set project_id [db_string project_id "select project_id from im_projects where lower(project_name) = lower(:project_name)"]

	db_dml update_project "
		update im_projects set
			project_path	= :project_path
		where
			project_id = :project_id
	"
	im_audit -object_id $project_id

	db_1row project_info "
		select project_id, main_office_id
		from im_projects
		where lower(project_name) = lower(:project_name)
	"
    }

    # -----------------------------------------------------------------
    # Update the Office
    # -----------------------------------------------------------------

    set update_sql "
    update im_offices set
	office_name = :office_name,
	phone = :business_phone,
	fax = :business_fax,
	address_line1 = trim(:business_street),
	address_line2 = trim(:business_street_2 || ' ' || :business_street_3),
	address_city = :business_city,
	address_postal_code = :business_postal_code,
	address_country_code = :business_country_code
    where
	office_id = :main_office_id
"
    db_dml update_offices $update_sql
    im_audit -object_id $main_office_id

    # -------------------------------------------------------
    # Deal with the users's project
    #
    set user_id 0
    set users_n [db_string person_count "select count(*) from persons where lower(first_names) = lower(:first_name) and lower(last_name) = lower(:last_name)"]
    if {0 != $users_n} {

        set user_id [db_string person_select "select person_id from persons where lower(first_names) = lower(:first_name) and lower(last_name) = lower(:last_name)" -default 0]
        set relationship_count [db_string relationship_count "select count(*) from acs_rels where object_id_one = :project_id and object_id_two = :user_id"]
        if {0 == $relationship_count} {
    	ns_write "<li>'$first_name $last_name': Adding as member to '$project'\n"
        im_biz_object_add_role $user_id $project_id [im_biz_object_role_full_member]
        } else {
    	ns_write "<li>'$first_name $last_name': Is already a member of project '$project'\n"
        }

    } else {
    
        ns_write "<li>The user '$first_name $last_name' doesn't exist in our database. <br>
        Please use the 'Import Users CSV' link in the users page to upload a list of users.\n"
        
    }

    # -----------------------------------------------------------------
    # Update the Project
    # -----------------------------------------------------------------

    # get everything about the project
    db_1row project_info "
    	select * 
    	from im_projects 
    	where project_id = :project_id
    "

    if {$primary_contact_id == "" && $user_id != 0} {
    	db_dml update_project_prim_contact "
    		update im_projects
    		set primary_contact_id = :user_id
    		where project_id = :project_id
    	"
    }

    if {$accounting_contact_id == "" && $user_id != 0} {
    	db_dml update_project_acc_contact "
    		update im_projects
    		set accounting_contact_id = :user_id
    		where project_id = :project_id
    	"
    }


    # Example:  "Comercial" "sales_rep_id" im_transform_email2user_id
    foreach trans $dynfield_trans_list {
	set excel_field [string tolower [lindex $trans 0]]
        set excel_field [string map -nocase {" " "_" "\"" "" "'" "" "/" "_" "-" "_" "\[" "(" "\{" "(" "\}" ")" "\]" ")"} $excel_field]
        set excel_field [im_mangle_unicode_accents $excel_field]
	set table_column [lindex $trans 1]
	set trans_function [lindex $trans 2]

	set excel_value ""
	if {[catch { 
	    set excel_value [string trim [expr \$$excel_field]]
	} err_value]} {
	    if {"" != $err_value} { 
		ns_write "
		<li>Error transforming value '$excel_value' of Excel field '$excel_field' into column '$table_column':<br>
		<pre>$err_value</pre>
	        "
	    }
	}

	if {"" != $excel_value} {

	    set res_list {}
	    set res_errors {"Error during transformation"}
	    
	    if {[catch {
		set trans_result [eval $trans_function $excel_value]
		set res_list [lindex $trans_result 0]
		set res_errors [lindex $trans_result 1]
	    } err_trans]} {
		if {"" != $err_value} { 
	            ns_write "
		    <li>Error transforming value '$excel_value' of Excel field '$excel_field' into column '$table_column':<br>
		    <pre>$err_trans</pre>
	            "
		}
	    }

	    if {[llength $res_errors] > 0 || [llength $res_list] != 1} {

		# Error
		ns_write "
	<li>Error transforming value '$excel_value' of Excel field '$excel_field' into column '$table_column':<br>
	[join $res_errors "<br>\n"]"

	    } else {

		# We found exactly one return value and no errors...
		set res [lindex $res_list 0]
	        db_dml update_project_dynfield "
	                update im_projects set 
				$table_column = :res
	                where project_id = :project_id
	        "
	    }
        }
    }

    im_audit -object_id $project_id

}

ns_write "\n</ul><p>\n<A HREF=$return_url>Return to Project Page</A>\n"


# ------------------------------------------------------------
# Render Report Footer

ns_write [im_footer]


