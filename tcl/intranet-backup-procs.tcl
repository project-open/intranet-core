# /packages/intranet-core/tcl/intranet-backup-procs.tcl
#
# Copyright (C) 1998 - 2009 ]project-open[ and others.
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


ad_register_proc GET /intranet/backups/* im_backup
ad_register_proc GET /intranet/admin/backup/download/* im_backup_download


# -------------------------------------------------------
# 
# -------------------------------------------------------

ad_proc -public im_backup_version_nr { } {
    Returns a version number

} {
    return "3.0"
}


ad_proc -public im_backup_accepted_version_nr { version } {
    Returns "" if the version of the import file is accepted
    or an error message otherwise.
} {
    switch $version {
	"3.0" { return "" }
	"3.1" { return "" }
	"3.2" { return "" }
	default { return "Unknown backup dump version '$version'<br>" }
    }
}


ad_proc -public im_backup_path { } {
    Returns the default path for the backup sets
} {
    set path [parameter::get -package_id [im_package_core_id] -parameter "BackupBasePathUnix" -default "/tmp"]

    return $path
}




# -------------------------------------------------------
# Backup Routines
# -------------------------------------------------------

ad_proc im_backup_download { } {
    Serves a specified backup file
} {
    set url [ns_conn url]
    set path_list [split $url {/}]
    set body [lrange $path_list end end]

    set body_pieces [split $body "."]
    set ext [lrange $body_pieces end end]

    # Check the URL and see if somebody is fiddeling around with URLs...
    set body_ok [regexp {^pg_dump(.*).sql(.*)$} $body match]
    if {[regexp {\.\.} $body match]} { set body_ok 0 }
    if {!$body_ok} {
	im_security_alert \
	    -location "Backup Download" \
	    -message "Intent to download bad backup file" \
	    -value $url \
	ad_script_abort
    }

    set file "[im_backup_path]/$body"

    set type [ns_guesstype $file]
    ns_returnfile 200 $type $file
}



# -------------------------------------------------------
# Lookup procedures for faster imports
# -------------------------------------------------------

ad_proc -public im_import_get_category { category category_type default } {
    Looks up a category or returns the default value
} {
    if {"" == $category} { return $default }
    set category_id [im_import_get_category_helper $category $category_type]

#    set category_id [util_memoize "im_import_get_category_helper \"$category\" \"$category_type\""]

    if {"" == $category_id} {
	set category_id $default
	set err "didn't find category '$category' of category type '$category_type'"
	ns_log Notice "im_import_get_category: $err"
	upvar 1 err_return err_return
	upvar 1 csv_line csv_line
	append err_return "<li>$csv_line<br>\n$err\n"
    }
    return $category_id
}

ad_proc -public im_import_get_category_helper { category category_type } {
    Performs the DB query to be cached
} {
    return [db_string get_category "select category_id from im_categories where category=:category and category_type=:category_type" -default ""]
}



ad_proc -public im_import_get_user { email default } {
    Looks up an email or returns the default value
} {
    if {"" == $email} { return $default }
    set user_id [util_memoize "im_import_get_user_helper \"$email\""]
    if {"" == $user_id} {
	set user_id $default
	set err "didn't find user '$email'"
	ns_log Notice "im_import_get_user: $err"
	upvar 1 err_return err_return
	upvar 1 csv_line csv_line
	append err_return "<li>$csv_line<br>\n$err\n"
    }
    return $user_id
}

ad_proc -public im_import_get_user_helper { email } {
    Performas the DB to looks up an email to be cached
} {
    return [db_string get_user "select party_id from parties where lower(email)=lower('$email')" -default ""]
}



# -------------------------------------------------------
# Backup Routines
# -------------------------------------------------------

ad_proc im_backup { } {
    Receives requests from /intranet/reports,
    exctracts parameters and calls the right report

} {
    set url "[ns_conn url]"
    set url [im_url_with_query]
    ns_log Notice "im_backup: url=$url"

    # /intranet/backup/im_projects
    # Using the report_id ("im_projects") as selector for various reports
    set path_list [split $url {/}]
    set len [expr [llength $path_list] - 1]

    # skip: +0:/ +1:intranet, +2:backups, +3:<file>, +4:...
    set report [lindex $path_list 3]
    ns_log Notice "im_backup: report_spec=$report"

    # Chop off a ".csv" ending
    if {[regexp {(.*)\.(.*)} $report match body extension]} {
	ns_log Notice "im_backup: found file with extension: $body - $extension"
	set report $body
    }


    set report_id [db_string get_report "select view_id from im_views where view_name=:report" -default 0]

    if {!$report_id} {
	ad_return_complaint 1 "<li>Invalid backup reprort '$report'. <br>Please see online documentation"
	return
    }

    set report [im_backup_report $report_id]

    db_release_unused_handles

    if {[string equal "csv" $extension]} {
	doc_return  200 "application/csv" $report
    } else {
	doc_return  200 "text/html" "<pre>\n$report\n</pre>\n"
    }
}




ad_proc -public im_backup_report { backup_id } {
    Execute an export backup
} {
    set user_id [ad_maybe_redirect_for_registration]
    set separator ";"

    if {![im_is_user_site_wide_or_intranet_admin $user_id]} {
	ad_return_complaint 1"<li>You have insufficient permissions to see this page."
	return
    }

    # Get the Backup SQL
    #
    set rows [db_0or1row get_backup_info "
select
	view_sql as backup_sql,
	view_name
from
	im_views
where
	view_id = :backup_id
"]
    if {!$rows} {
	ad_return_complaint 1 "<li>Unknown backup \#$backup_id"
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
	view_id=:backup_id
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

    # Execute the backup
    #
    set ctr 0
    set results ""
    db_foreach projects_info_query $backup_sql {

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

    set version "
	<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>
	[im_backup_version_nr] $view_name
    "

    return "$version\n$header\n$results\n"
}



# -------------------------------------------------------
# Categories
# -------------------------------------------------------

ad_proc -public im_import_categories { filename } {
    Import categories
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_categories"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set category_description [ns_urldecode $category_description]
	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set already_exists [db_string cat_already_exists "select count(*) from im_categories where category=:category and category_type=:category_type"]
	set id_occupied 0
	if {!$already_exists} {
	    set id_occupied [db_string id_occupied "select count(*) from im_categories where category_id = :category_id"]
	}

	ns_log Notice "im_import_categories: category=$category"
	ns_log Notice "im_import_categories: category_type=$category_type"
	ns_log Notice "im_import_categories: already_exists=$already_exists"
	ns_log Notice "im_import_categories: id_occupied=$id_occupied"

	if {!$id_occupied} {
	    set create_member_sql "
		insert into im_categories
			(category_id, category, category_description, category_type,
			 category_gif, enabled_p, parent_only_p)
		values
			(:category_id, :category, :category_description, :category_type,
			 :category_gif, :enabled_p, :parent_only_p)"
	} else {
	    set create_member_sql "
		insert into im_categories
		    (category_id, category, category_description, category_type,
		     category_gif, enabled_p, parent_only_p)
		values
		  (:category_id, :category, :category_description, :category_type,
		  :category_gif, :enabled_p, :parent_only_p)"
	}

	if { [catch {

	    if {!$already_exists} {
		set category_id [db_nextval im_categories_seq]
		db_dml create_member $create_member_sql
	    }

	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading categories: line $i<br>
	    $csv_line<br>
	    <pre>\n$err_msg</pre>"
	}

    }
    return $err_return
}




# -------------------------------------------------------
# Companies
# -------------------------------------------------------

ad_proc -public im_import_companies { filename } {
    Import the companies file
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_companies"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	set manager_id [im_import_get_user $manager_email ""]
	set accounting_contact_id [im_import_get_user $accounting_contact_email ""]
	set primary_contact_id [im_import_get_user $primary_contact_email ""]
	set company_type_id [im_import_get_category $company_type "Intranet Company Type" 51]
	set company_status_id [im_import_get_category $company_status "Intranet Company Status" 46]
	set crm_status_id [im_import_get_category $crm_status "Intranet Company CRM Status" ""]
	set annual_revenue_id [im_import_get_category $annual_revenue "Intranet Annual Revenue" ""]

	set main_office_id [db_string main_office "select office_id from im_offices where office_name=:main_office_name" -default ""]
	if {"" == $main_office_id} { append err_return "<li>didn't find main office '$main_office_name'" }

	# Check if the company already exists..
	set company_id [db_string company "select company_id from im_companies where company_name=:company_name" -default 0]
	# -------------------------------------------------------
	# Prepare the DB statements
	#
	db_1row "get sysdate" "select sysdate as sysdate from dual"

	set update_company_sql "
UPDATE im_companies
SET
	deleted_p=:deleted_p,
	company_status_id=:company_status_id,
	company_type_id=:company_type_id,
	note=:note,
	referral_source=:referral_source,
	annual_revenue_id=:annual_revenue_id,
	status_modification_date=:sysdate,
	billable_p=:billable_p,
	site_concept=:site_concept,
	manager_id=:manager_id,
	contract_value=:contract_value,
	start_date=:sysdate,
	primary_contact_id=:primary_contact_id,
	main_office_id=:main_office_id,
	vat_number=:vat_number
WHERE
	company_name = :company_name"


	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "company_name	$company_name"
	ns_log Notice "company_path	$company_path"
	ns_log Notice "main_office_id	$main_office_id"	


	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    if {0 == $company_id} {
		# The company doesn't exist yet:
		set company_id [db_exec_plsql company_create {}]
	    }
	    db_dml update_company_sql $update_company_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading companies:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }

    return $err_return
}




ad_proc -public im_import_company_members { filename } {
    Import the users associated with companies
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_company_members"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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

	set object_id [db_string company "select company_id from im_companies where company_name=:company_name" -default ""]
	if {"" == $object_id} { append err_return "<li>didn't find company '$company_name'" }

	set user_id [im_import_get_user $user_email ""]
	set object_role_id [im_import_get_category $role "Intranet Biz Object Role" ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#


	# -------------------------------------------------------
	# Debugging
	#
	set debug "object_id=$object_id\nuser_id=$user_id\nobject_role_id $object_role_id"
	ns_log Notice "im_import_company_members: $debug"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string count_members "select count(*) from acs_rels where object_id_one=:object_id and object_id_two=:user_id"]
	    if {!$count} {
		set rel_id [db_exec_plsql create_member {}]
	    }
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading company members:<br>
	    $csv_line<br>
	    <pre>$debug</pre><br>
	    <pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}





# -------------------------------------------------------
# Offices
# -------------------------------------------------------

ad_proc -public im_import_offices { filename } {
    Import the offices file
} {
    ns_log Notice "im_import_offices($filename)"

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_offices"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
    }

    set csv_header [lindex $csv_lines 1]
    # Splits a line from a CSV (Comma Separated Format)
    set csv_header_fields [im_csv_split $csv_header ";"]

    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [im_csv_split $csv_line ";"]
	ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line} {
	    ns_log Notice "skipping empty line"
	    continue
	}


	# -------------------------------------------------------
	# Set default variables that are not filled by older
	# backup versions
	#
	set office_type ""
	set office_status ""

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
	set address_line1 [ns_urldecode $address_line1]
	set address_line2 [ns_urldecode $address_line2]
	set address_city [ns_urldecode $address_city]
	set landlord [ns_urldecode $landlord]
	set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	set office_type_id [im_import_get_category $office_type "Intranet Office Type" 170]
	set office_status_id [im_import_get_category $office_status "Intranet Office Status" 160]
	set contact_person_id [im_import_get_user $contact_person_email ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

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

	    set office_id [db_string office "select office_id from im_offices where office_name=:office_name" -default 0]
	    if {!$office_id} {
		# The office doesn't exist yet:
		set office_id [db_exec_plsql  office_create {}]
	    }
	    db_dml update_office_sql $update_office_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading offices:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}




ad_proc -public im_import_office_members { filename } {
    Import the users associated with offices
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_office_members"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set user_id [im_import_get_user $user_email ""]
	set object_role_id [im_import_get_category $role "Intranet Biz Object Role" ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#


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
		set member_id [db_exec_plsql create_member {}]
	    }
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading office members:<br>
	    $csv_line<br><pre>\n$err_msg<pre>"
	}
    }
    return $err_return
}


# -------------------------------------------------------
# Projects
# -------------------------------------------------------

ad_proc -public im_import_projects { filename } {
    Import the projects file
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_projects"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set description [ns_urldecode $description]
	set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	set project_lead_id [im_import_get_user $project_lead_email ""]
	set supervisor_id [im_import_get_user $supervisor_email ""]
	set project_type_id [im_import_get_category $project_type "Intranet Project Type" ""]
	set project_status_id [im_import_get_category $project_status "Intranet Project Status" ""]
	set billing_type_id [im_import_get_category $billing_type "Intranet Billing Type" ""]

	set company_id [db_string company "select company_id from im_companies where company_name=:company_name" -default 0]
	set project_id [db_string project "select project_id from im_projects where project_name=:project_name" -default 0]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set update_project_sql "
UPDATE im_projects
SET
	project_name		= :project_name,
	project_nr		= :project_nr,
	project_path		= :project_path,
	company_id		= :company_id,
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
	ns_log Notice "company_id	$company_id"
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
		set project_id [db_exec_plsql project_create {}]
	    }
	    db_dml update_project_sql $update_project_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading projects:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
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
    return $err_return
}


ad_proc -public im_import_project_members { filename } {
    Import the users associated with projects
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_project_members"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set user_id [im_import_get_user $user_email ""]
	set object_role_id [im_import_get_category $role "Intranet Biz Object Role" ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

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
		set rel_id [db_exec_plsql create_member {}]
	    }
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading members:<br>
	    $csv_line<br><pre>\n$err_msg<pre>"
	}
    }
    return $err_return
}





# -------------------------------------------------------
# Users
# -------------------------------------------------------



ad_proc -public im_import_users { filename } {
    Import the user information
} {
    set err_return ""
    ns_log Notice "im_import_users $filename"

    if {![file readable $filename]} {
	append err_return "<li>Unable to read file '$filename'"
	return $err_return
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
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_users"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	    append err_return "<li>Found a user without email address:<br>
	    User '$first_names $last_name' doesn't have an email address
	    and thus cannot be inserted into the database."
	}

	if {"" == $username} {
	    set username [string tolower "$first_names $last_name"]
	}
	

	# -------------------------------------------------------
	# Prepare the DB statements
	#

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
	home_phone	      = :home_phone,
	work_phone	      = :work_phone,
	cell_phone	      = :cell_phone,
	pager		   = :pager,
	fax		     = :fax,
	aim_screen_name	 = :aim_screen_name,
	msn_screen_name	 = :msn_screen_name,
	icq_number	      = :icq_number,
	ha_line1		= :ha_line1,
	ha_line2		= :ha_line2,
	ha_city		 = :ha_city,
	ha_state		= :ha_state,
	ha_postal_code	  = :ha_postal_code,
	ha_country_code	 = :ha_country_code,
	wa_line1		= :wa_line1,
	wa_line2		= :wa_line2,
	wa_city		 = :wa_city,
	wa_state		= :wa_state,
	wa_postal_code	  = :wa_postal_code,
	wa_country_code	 = :wa_country_code,
	note		    = :note
WHERE
	user_id=:user_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	set count [db_string user "select count(*) from parties where lower(email)=lower(:email)"]
	if {!$count} {
	    if { [catch {
		set user_id [db_exec_plsql create_user {}]
		
		#db_dml create_user create_user_sql
		db_dml create_contact "INSERT INTO users_contact (user_id) 
                                       VALUES (:user_id);"
		db_1row "registered_user " "select object_id as registered_users
                                            from acs_magic_objects
                                            where name='registered_users'"
		db_1row "is registered" "    select count(*) as rel_count
                                             from acs_rels
                                             where object_id_one = :registered_users
                                             and object_id_two = :user_id"
		if {0 == $rel_count} {
		    set rel_id [db_exec_plsql  add_to_registered_users {}]
		}
	    } err_msg] } {
		append err_return "<li>Error loading users 1:<br>
		$csv_line<br>
		<pre>\n$err_msg</pre>"
	    }
	}

	set user_id [db_string get_user "select party_id from parties where lower(email)=lower(:email)" -default 0]

	if {$user_id} {
	    if { [catch {
		db_dml update_users $update_users_sql
		db_dml update_parties $update_parties_sql
		db_dml update_persons $update_persons_sql
		db_dml update_users_contact $update_users_contact_sql
	    } err_msg] } {
		ns_log Warning "$err_msg"
		append err_return "<li>Error loading users 2:<br>
	    $csv_line<br>
	    <pre>\n$err_msg</pre>"
	    }

	    ad_change_password $user_id $password
	
	} else {
	    append err_return "<li>Unable to identify user_id from '$email'\n"
	}
    }
    return $err_return
}




ad_proc -public im_import_profiles { filename } {
    Import the user/profile membership
} {
    ns_log Notice "im_import_profiles $filename"
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_profiles"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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

	set profile_id [db_string profile "select group_id from groups where group_name=:profile_name" -default ""]
	if {"" == $profile_id} { append err_return "<li>didn't find profile $profile_name" }

	set user_id [im_import_get_user $user_email 0]
	ns_log notice "****************** user_id $user_id ***************"
	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set insert_profile_sql "
BEGIN
     FOR row IN (
	select
		r.rel_id
	from
		acs_rels r,
		acs_objects o
	where
		object_id_two = :user_id
		and object_id_one = :profile_id
		and r.object_id_one = o.object_id
		and o.object_type = 'im_profile'
		and rel_type = 'membership_rel'
     ) LOOP
	 membership_rel.del(row.rel_id);
     END LOOP;

     :1 := membership_rel.new(
	object_id_one    => :profile_id,
	object_id_two    => :user_id,
	member_state     => 'approved'
     );
END;
"
	# -------------------------------------------------------
	# Debugging
	#
	ns_log Notice "im_import_profiles: profile_id	$profile_id"
	ns_log Notice "im_import_profiles: user_id	$user_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#
	if { [catch {
	db_foreach "get rels" "select r.rel_id
	from
		acs_rels r,
		acs_objects o
	where
		object_id_two = :user_id
		and object_id_one = :profile_id
		and r.object_id_one = o.object_id
	        and o.object_type = 'im_profile'
	        and rel_type = 'membership_rel'" {

            db_exec_plsql delete_rels {}
	}
	    db_exec_plsql insert_profile {}

	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error adding user to profile:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}







# -------------------------------------------------------
# Freelancers
# -------------------------------------------------------


ad_proc -public im_import_freelancers { filename } {
    Import the freelancer information
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
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
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_freelancers"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set user_id [im_import_get_user $user_email ""]
	set payment_method_id [im_import_get_category $payment_method "Intranet Payment Type" ""]

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
	    append err_return "<li>Error loading freelancers:<br> <pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}

 
# -------------------------------------------------------
# Freelancers
# -------------------------------------------------------

ad_proc -public im_import_employees { filename } {
    Import the employees information
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
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
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_employees"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set job_description [ns_urldecode $job_description]
	#set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set employee_id [im_import_get_user $employee_email ""]
	set department_id [db_string deparment "select cost_center_id \
                             from im_cost_centers where cost_center_label = :department_label" -default ""]
	set supervisor_id [im_import_get_user $supervisor_email ""]
	set referred_by [im_import_get_user $referred_by_email ""]
	
	set employee_status_id [im_import_get_category $employee_status "Intranet Employee Pipeline State" ""]
	set experience_id [im_import_get_category $experience "Intranet Prior Experience" ""]
	
	set source_id [im_import_get_category $source "Intranet Hiring Source" ""]
	set original_job_id [im_import_get_category $original_job "Intranet Job Title" ""]

	set current_job_id [im_import_get_category $current_job "Intranet Job Title" ""]
	set qualification_id [im_import_get_category $qualification "Intranet Qualification Process" ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_sql "INSERT INTO im_employees (employee_id) values (:employee_id)"
	set update_sql "
UPDATE im_employees
SET
	department_id	        = :department_id,
	job_title		= :job_title,
	job_description		= :job_description,
	availability		= :availability,
	supervisor_id		= :supervisor_id,
	ss_number	        = :ss_number,
	salary			= :salary,
	social_security		= :social_security,
        insurance               = :insurance,
        other_costs             = :other_costs,
        currency                = :currency,
        salary_period           = :salary_period,
        salary_payments_per_year = :salary_payments_per_year,
        dependant_p             = :dependant_p,
        only_job_p              = :only_job_p,
        married_p               = :married_p,
        dependants              = :dependants,
        head_of_household_p     = :head_of_household_p,     
        birthdate               = :birthdate,               
        skills                  = :skills,                  
        first_experience        = :first_experience,        
        years_experience        = :years_experience,        
        educational_history     = :educational_history,
        last_degree_completed   = :last_degree_completed,   
        employee_status_id      = :employee_status_id,      
        termination_reason      = :termination_reason,      
        voluntary_termination_p = :voluntary_termination_p, 
        signed_nda_p            = :signed_nda_p,            
        referred_by             = :referred_by,             
        experience_id           = :experience_id,
        source_id               = :source_id,               
        original_job_id         = :original_job_id,         
        current_job_id          = :current_job_id,          
        qualification_id        = :qualification_id        

WHERE
	employee_id = :employee_id
"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "user_id			$employee_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string count_members "select count(*) from im_employees where employee_id=:employee_id"]
	    if {!$count} {
		db_dml create_member $create_sql
	    }
	    db_dml update_freelancer $update_sql
	
	 } err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading employees:<br> <pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}




ad_proc -public im_import_freelance_skills { filename } {
    Import the freelance skill database
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
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
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_freelance_skills"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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

	set skill_type_id [im_import_get_category $skill_type "Intranet Skill Type" ""]
	set skill_category_type [db_string skill_category "select category_description from im_categories where category_id=:skill_type_id"]

	set skill_id [im_import_get_category $skill $skill_category_type ""]

	set user_id [im_import_get_user $user_email ""]
	set claimed_experience_id [im_import_get_category $claimed_experience "Intranet Experience Level" ""]
	set confirmed_experience_id [im_import_get_category $confirmed_experience "Intranet Experience Level" ""]
	set confirmation_user_id [im_import_get_user $confirmation_user_email ""]

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

	set update_sql "
UPDATE im_freelance_skills
SET
	claimed_experience_id	=:claimed_experience_id,
	confirmed_experience_id	=:confirmed_experience_id,
	confirmation_user_id	=:confirmation_user_id,
	confirmation_date	=:confirmation_date
WHERE
	user_id=:user_id
	and skill_id=:skill_id
	and skill_type_id=:skill_type_id
"	

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "skill_type_id	$skill_type_id"
	ns_log Notice "skill_category_tyle	$skill_category_type"
	ns_log Notice "skill_id		$skill_id"
	ns_log Notice "user_id		$user_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string freelance_skill_count "select count(*) from im_freelance_skills where user_id=:user_id and skill_id=:skill_id and skill_type_id=:skill_type_id"]
	    if {!$count} {
		db_dml create_freelance_skill $create_sql
	    } else {
		db_dml update_freelance_skill $update_sql
	    }
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading freelance_skills:<br>
	    <pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}







# -------------------------------------------------------
# Hours
# -------------------------------------------------------


ad_proc -public im_import_hours { filename } {
    Import timesheet hour information
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
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
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_hours"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set user_id [im_import_get_user $user_email ""]
	set project_id [db_string project "select project_id from im_projects where project_name=:project_name" -default ""]


	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_sql "
INSERT INTO im_hours (
	user_id,
	project_id,
	day,
	hours,
	billing_rate,
	billing_currency,
	note
) values (
	:user_id,
	:project_id,
	:day,
	:hours,
	:billing_rate,
	:billing_currency,
	:note
)"

	set update_sql "
UPDATE im_hours
SET
	hours			= :hours,
	billing_rate		= :billing_rate,
	billing_currency	= :billing_currency,
	note			= :note
WHERE
	user_id=:user_id
	and project_id=:project_id
	and day=:day
"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "user_id			$user_id"
	ns_log Notice "project_id		$project_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    set count [db_string count "select count(*) from im_hours where user_id=:user_id and project_id=:project_id and day=:day"]
	    if {!$count} {
		db_dml create $create_sql
	    }
	    db_dml update $update_sql
	
	 } err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading hours:<br>
	    <pre>$csv_line</pre><br>
	    <pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}


# -------------------------------------------------------
# user absences
# -------------------------------------------------------

ad_proc -public im_import_user_absences { filename } {
    Import the user absences file
} {
    
    set user_id [ad_maybe_redirect_for_registration]
    
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }
    
    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]
    
    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_user_absences"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	    append err_return "<li>Skipping line '$csv_line'"
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
	
	set description [ns_urldecode $description]
	
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	# Use "" as default values because most of these
	# values are optional.
        #
	set owner_id [im_import_get_user "$owner_email" ""]
	set absence_type [im_import_get_category $absence_type "Intranet Absence Type" ""]
	set sysdate [db_string "get sysdate" "select sysdate from dual"]
	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_absence_sql "
INSERT INTO im_user_absences (
        absence_id,
        start_date,
        end_date,
        absence_type_id
) values (
        :absence_id,
        :start_date,
        :end_date,
        :absence_type
)"


	set update_absence_sql "
UPDATE im_user_absences
SET
        owner_id                = :owner_id,
        start_date		= :start_date,
        end_date		= :end_date,
        description             = :description,
        contact_info	        = :contact_info,
        receive_email_p 	= :receive_email_p,
        last_modified		= :sysdate,
        absence_type_id         = :absence_type
WHERE
        absence_id = :absence_id
"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {
	
	    set absence_id [db_string absence_id "
select 
	absence_id 
from
	im_user_absences
where 
	owner_id = :owner_id 
	and start_date = :start_date 
	" -default 0]

	    if {0 == $absence_id} {
		# The absence doesn't exist yet:
	        set absence_id [db_nextval im_user_absences_id_seq]
		db_dml absence_create $create_absence_sql
	    }
	    db_dml update_absence $update_absence_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading absence:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }

    return $err_return
}





# -------------------------------------------------------
# Translation
# -------------------------------------------------------


ad_proc -public im_import_trans_project_details { filename } {
    Import timesheet hour information
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
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
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_trans_project_details"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set final_company [ns_urldecode $final_company]
	set company_project_nr [ns_urldecode $company_project_nr]
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set project_id [db_string project "select project_id from im_projects where project_nr=:project_nr" -default ""]
	set company_contact_id [im_import_get_user $company_contact_email ""]

	set source_language_id [im_import_get_category $source_language "Intranet Translation Language" ""]
	set subject_area_id [im_import_get_category $subject_area "Intranet Translation Subject Area" ""]
	set expected_quality_id [im_import_get_category $expected_quality "Intranet Quality" ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set update_sql "
UPDATE im_projects
SET
	company_project_nr	= :company_project_nr,
	company_contact_id	= :company_contact_id,
	source_language_id	= :source_language_id,
	subject_area_id		= :subject_area_id,
	expected_quality_id	= :expected_quality_id,
	final_company		= :final_company
WHERE
	project_id = :project_id
"

	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "project_id		$project_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    db_dml update $update_sql
	
	 } err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error updating translation project extensions:<br>
	    <pre>$csv_line</pre><br>
	    <pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}




ad_proc -public im_import_trans_tasks { filename } {
    Import timesheet hour information
} {
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
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
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_trans_tasks"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

#	if {$i > 50} { return $err_return }

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
	set task_name [ns_urldecode $task_name]
	set task_filename [ns_urldecode $task_filename]
	set description [ns_urldecode $description]
	# -------------------------------------------------------
	# Transform categories, email and names into IDs
	#

	set project_id [db_string project "select project_id from im_projects where project_name=:project_name" -default ""]
        set invoice_id [db_string invoice_id "select invoice_id from im_invoices where invoice_nr=:invoice_nr" -default ""]

	set source_language_id [im_import_get_category $source_language "Intranet Translation Language" 290]
	set target_language_id [im_import_get_category $target_language "Intranet Translation Language" 290]

	set task_type_id [im_import_get_category $task_type "Intranet Project Type" ""]
	set task_status_id [im_import_get_category $task_status "Intranet Translation Task Status" ""]

	set task_uom_id [im_import_get_category $task_uom "Intranet UoM" ""]

	set trans_id [im_import_get_user $trans_email ""]
	set edit_id [im_import_get_user $edit_email ""]
	set proof_id [im_import_get_user $proof_email ""]
	set other_id [im_import_get_user $other_email ""]

	if {"" == $task_name} {
	    set task_name $project_name
	    set task_filename $project_name
	}

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set insert_sql "
    INSERT INTO im_trans_tasks (
	task_id,
	project_id,
	invoice_id,
	target_language_id,
	task_name,
	task_filename,
	task_type_id,
	task_status_id,
	description,
	source_language_id,
	task_units,
	billable_units,
	task_uom_id,
	match100,
	match95,
	match85,
	match0,
	trans_id,
	edit_id,	
	proof_id,	
	other_id
    ) VALUES (
	:task_id,
	:project_id,
	:invoice_id,
	:target_language_id,
	:task_name,
	:task_filename,
	:task_type_id,
	:task_status_id,
	:description,
	:source_language_id,
	:task_units,
	:billable_units,
	:task_uom_id,
	:match100,	
	:match95,	
	:match85,	
	:match0,	
	:trans_id,	
	:edit_id,
	:proof_id,	
	:other_id
    )
"

	set update_sql "
UPDATE im_trans_tasks
SET
	invoice_id		= :invoice_id,
	task_filename		= :task_filename,
	task_type_id		= :task_type_id,
	task_status_id		= :task_status_id,
	description		= :description,
	source_language_id	= :source_language_id,
	task_units		= :task_units,
	billable_units		= :billable_units,
	task_uom_id		= :task_uom_id,
        match_x                 = :match_x,
        match_rep               = :match_rep,
	match100		= :match100,
	match95			= :match95,
	match85			= :match85,
        match75                 = :match75,
        match50                 = :match50,
	match0			= :match0,
	trans_id		= :trans_id,
	edit_id			= :edit_id,	
	proof_id		= :proof_id,
	other_id		= :other_id
WHERE
	task_name=:task_name
	and project_id=:project_id
	and target_language_id=:target_language_id
"

	# -------------------------------------------------------
	# Debugging
	#

	set debug "
project_id=$project_id
target_language_id=$target_language_id
task_name=$task_name
"
	ns_log Notice $debug

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#


	set task_id [db_string project "select task_id from im_trans_tasks where task_name=:task_name and project_id=:project_id and target_language_id=:target_language_id" -default 0]

	if { [catch {

	    if {!$task_id} {
		set task_id [db_nextval im_trans_tasks_seq]
#		db_dml update $insert_sql
	    }

	    db_dml update $update_sql


	 } err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error updating translation project extensions:<br>
	    <pre>$csv_line</pre><br>
	    <pre>$debug</pre><br>
	    <pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}

# -------------------------------------------------------
# Costs
# -------------------------------------------------------

ad_proc -public im_import_costs { filename } {
    Import the costs file
} {
    set parent_list_of_lists [list]
    set user_id [ad_maybe_redirect_for_registration]

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_costs"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	# continue here
	
	set cost_id [db_string cost_id "select cost_id \
                        from im_costs where cost_nr=:cost_nr" -default 0]

        set customer_id [db_string customer "select company_id \
                        from im_companies where company_name=:customer_name" -default 0]

	set provider_id [db_string provider "select company_id \
                        from im_companies where company_name=:provider_name" -default 0]

	set creator_id [im_import_get_user $creator_email ""]
	
	set project_id [db_string project "select project_id \
                        from im_projects where project_name = :project_name" -default ""]
	
	set investment_id [db_string investment {\
			   select investment_id \
			   from im_investments \
			   where name = :investment_name} -default 0]
	set cost_center_id [db_string cost_center "select cost_center_id \
                           from im_cost_centers \
                           where cost_center_name = :cost_center_label" -default ""]
    
	set template_id [im_import_get_category $template "Intranet Cost Template" ""]
	set cost_status_id [im_import_get_category $cost_status "Intranet Cost Status" 0]
	set cost_type_id [im_import_get_category $cost_type "Intranet Cost Type" ""]
	
	####################
	#
	# 20041014 avila@digiteix.com
	# ------------------
	# in the first step insert null in parent field
	# update parent info when all costs are in the DB

	set parent_id ""

	set modifying_user [im_import_get_user $last_modifying_email ""]
	
	# Old style invoices - provider was Internal by default
	# set provider_id [im_company_internal]


	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set update_cost_sql "
UPDATE im_costs
SET
        cost_name            = :cost_name,
        cost_nr              = :cost_nr,
        customer_id          = :customer_id,
        provider_id          = :provider_id,
        project_id           = :project_id,
        start_block          = :start_block,
        effective_date       = :effective_date,
        investment_id        = :investment_id,
        cost_center_id       = :cost_center_id,
        currency             = :currency,
        template_id          = :template_id,
        cost_status_id       = :cost_status_id,
        cost_type_id         = :cost_type_id,
        payment_days         = :payment_days,
        vat                  = :vat,
        tax                  = :tax,
	note		     = :note,
        amount               = :amount,
        variable_cost_p      = :variable_cost_p,
        needs_redistribution_p = :needs_redistribution_p,
        parent_id            = :parent_id,
        redistributed_p      = :redistributed_p,
        planning_p           = :planning_p,
        planning_type_id     = :planning_type_id,
        description          = :description,
        paid_amount          = :paid_amount,
        paid_currency        = :paid_currency        
WHERE
	cost_id = :cost_id"


	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "cost_id	$cost_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#
	if { [catch {

	    if {0 == $cost_id} {
		# The invoice doesn't exist yet:
		set cost_id [db_exec_plsql create_cost {}]
	    }
	    db_dml update_cost $update_cost_sql
	    db_dml "update object info" "update acs_objects set
                       modifying_user = :modifying_user,
                       last_modified = :last_modified,
                       modifying_ip = :modifying_ip
                    where object_id = :cost_id"
	    set parent_element [list $cost_id $parent_cost_nr]
	    lappend parent_list_of_lists $parent_element
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading costs:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }
    # update parent info
    
    foreach parent_l $parent_list_of_lists {
	set c_id [lindex $parent_l 0]
	set parent_cost_nr [lindex $parent_l 1]
	#set parent_cost_nr [lindex $p_info_list 0]
	#set start_block [lindex $p_info_list 1]

	# get parent_cost_id
	if {"" != $parent_cost_nr} {
	    if {![db_0or1row "get parent_cost_id" "selenct cost_id as parent_id \
                          from im_costs \
                          where cost_nr = :parent_cost_nr"]} {
		set parent_id "0"
	    }
	    if { [catch {
		db_dml "update parent" "update im_costs set parent_id = :parent_id
                                where cost_id = :c_id"
	    } err_msg] } {
		ns_log Warning "$err_msg"
		append err_return "<li>Error updating parent costs:<br>
	    <br><pre>\n$err_msg</pre>"
	    }
	}
    }
    return $err_return
}

####
ad_proc -public im_import_cost_centers { filename } {
    Import the costs file
} {
    set parent_list_of_lists [list]
    set user_id [ad_maybe_redirect_for_registration]

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_cost_centers"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set note [ns_urldecode $note]
	set description [ns_urldecode $description]
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

	# continue here
	
	set manager_id [im_import_get_user $manager_email ""]
       
	set cost_center_id [db_string cost_center "select cost_center_id \
                           from im_cost_centers \
                           where cost_center_name = :cost_center_label" -default ""]
    
	set cost_center_status_id [im_import_get_category $cost_center_status "Intranet Cost Center Status" 0]
	set cost_center_type_id [im_import_get_category $cost_center_type "Intranet Cost Center Type" ""]
	
	####################
	#
	# 20041014 avila@digiteix.com
	# ------------------
	# in the first step insert null in parent field
	# update parent info when all costs are in the DB

	set parent_id ""
	set creator_id ""
	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set update_cost_centers_sql "
UPDATE im_cost_centers
SET
        cost_center_name     = :cost_center_name,
        cost_center_label    = :cost_center_label,
        cost_center_code     = :cost_center_code,
        cost_center_status_id       = :cost_center_status_id,
        cost_center_type_id         = :cost_center_type_id,
        department_p      = :department_p,
        parent_id            = :parent_id,
        manager_id      = :manager_id,
        note          = :note
WHERE
	cost_center_id = :cost_center_id"


	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "cost_center_id	$cost_center_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#
	if { [catch {

	    if {0 == $cost_center_id} {
		# The cost center doesn't exist yet:
		set cost_center_id [db_exec_plsql create_cost_center {}]
	    }
	    db_dml update_cost_center $update_cost_centers_sql
	    set parent_element [list $cost_center_id $parent_label]
	    lappend parent_list_of_lists $parent_element
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading cost centers:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	    
	}
    }
    # update parent info
    
    foreach parent_l $parent_list_of_lists {
	set c_center_id [lindex $parent_l 0]
	set parent_cost_center_label [lindex $parent_l 1]
	# get parent_cost_center_id
	if {"" != $parent_cost_center_label} {
	    if {![db_0or1row "get parent_cost_center_id" "selenct cost_center_id as parent_id \
                          from im_cost_centers \
                          where cost_center_label = :parent_cost_center_label"]} {
		set parent_id "0"
	    }
	    if { [catch {
		db_dml "update parent" "update im_cost_centers set parent_id = :parent_id
                                where cost_center_id = :c_center_id"
	    } err_msg] } {
		ns_log Warning "$err_msg"
		append err_return "<li>Error updating parent cost centers:<br>
	    <br><pre>\n$err_msg</pre>"
	    }
	}
    }
    return $err_return
}



# -------------------------------------------------------
# Invoices
# -------------------------------------------------------

ad_proc -public im_import_invoices { filename } {
    Import the invoices file
} {

    set user_id [ad_maybe_redirect_for_registration]
    set ref_doc_list_of_list [list]
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_invoices"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	if {![empty_string_p $start_block]} {
	    set start_block_cond " = :start_block"
	} else {
	    set start_block_cond " is null"
	}
	set invoice_id [db_string invoice_id "select cost_id \
                       from im_costs where cost_nr = :cost_nr \
                       and start_block $start_block_cond" -default 0]
	#ad_return_error "***********" "cost_nr $cost_nr start_block $start_block -----> $invoice_id ******"
	#ad_script_abort
	set company_contact_id [im_import_get_user $company_contact_email ""]
	
	set payment_method_id [im_import_get_category $payment_method "Intranet Invoice Payment Method" ""]

	####################
	#
	# 20041014 avila@digiteix.com
	# ------------------
	# in the first step insert null in reference_document field
	# update reference info when all invoices are in the DB
	
	set reference_document_id ""

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_invoice_sql "
insert into im_invoices (
                invoice_id,
                company_contact_id,
                invoice_nr,
                payment_method_id
       ) values (
                :invoice_id,
                :company_contact_id,
                :invoice_nr,
                :payment_method_id
		)
"

	set update_invoice_sql "
UPDATE im_invoices
SET
        invoice_nr              = :invoice_nr,
        company_contact_id      = :company_contact_id,
        payment_method_id       = :payment_method_id
WHERE
	invoice_id = :invoice_id"


	# -------------------------------------------------------
	# Debugging
	#

	ns_log Notice "invoice_nr	$invoice_nr"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {
            db_1row "exist invoice_id" "select count(*) as exist_invoice from im_invoices where invoice_id = :invoice_id"
	    if {0 == $exist_invoice} {
		# The invoice doesn't exist yet:
		db_dml invoice_create $create_invoice_sql
	    }
	    db_dml update_invoice $update_invoice_sql
	    set reference_document_list [list $invoice_id $reference_document_nr]
            lappend ref_doc_list_of_list $reference_document_list

	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading invoices:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }
    # update reference_document info
    foreach ref_doc_list $ref_doc_list_of_list {
        set invoice_id [lindex $ref_doc_list 0]
        set ref_doc_nr [lindex $ref_doc_list 1]

        set reference_document_id [db_string reference_document "select invoice_id from im_invoices where invoice_nr = :ref_doc_nr" -default ""]
        if { [catch {
             db_dml "update reference_document" "update im_invoices set reference_document_id = :reference_document_id where invoice_id = :invoice_id"
        } err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error updating reference document invoices:<br>
	    $ref_doc_nr<br><pre>\n$err_msg</pre>"
	}
    }
    return $err_return
}


ad_proc -public im_import_invoice_items { filename } {
    Import the invoice_items file
} {

    set user_id [ad_maybe_redirect_for_registration]

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_invoice_items"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	set item_name [ns_urldecode $item_name]
	set description [ns_urldecode $description]

	# -------------------------------------------------------
	# Transform email and names into IDs
	#

        set invoice_id [db_string invoice_id "select invoice_id from im_invoices where invoice_nr=:invoice_nr" -default 0]
        set project_id [db_string project "select project_id from im_projects where project_name=:project_name" -default ""]
	set item_uom_id [im_import_get_category $item_uom "Intranet UoM" 0]

	# There are no categories defined yet for invoice item status and type.
	# So we use invoice status and project type meanwhile...
	# 
	set item_status_id [im_import_get_category $item_status "Intranet Invoice Status" ""]
	set item_type_id [im_import_get_category $item_type "Intranet Project Type" ""]

	
	if {"" == $item_units} { set item_units 0 }

	# Skip empty invoice_item lines if quantity and UoM are null
	if {0 == $item_units && "" == $item_uom } {
	    append err_return "<li>Skipping im_invoice_item with 
		item_name=$item_name<br>
		item_units=$item_units<br>
		item_uom=$item_uom"
	    continue
	}

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_invoice_item_sql "
INSERT INTO im_invoice_items (
	item_id,
	item_name,
	project_id,
	invoice_id,
	item_uom_id
) values (
	:item_id,
	:item_name,
	:project_id,
	:invoice_id,
	:item_uom_id
)"
	
	set update_invoice_item_sql "
UPDATE im_invoice_items
SET
        item_name               = :item_name,
        project_id              = :project_id,
        invoice_id              = :invoice_id,
        item_units              = :item_units,
        item_uom_id             = :item_uom_id,
        price_per_unit          = :price_per_unit,
        currency                = :currency,
        sort_order              = :sort_order,
        item_type_id            = :item_type_id,
        item_status_id          = :item_status_id,
        description             = :description
WHERE
	item_id = :item_id"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	# Check if we have already created the item
        set item_id [db_string item_id "select item_id from im_invoice_items where item_name=:item_name and invoice_id=:invoice_id and project_id=:project_id and item_uom_id=:item_uom_id" -default 0]

	if { [catch {

	    if {0 == $item_id} {
		# The invoice doesn't exist yet:
		set item_id [db_nextval im_invoice_items_seq]
		db_dml invoice_item_create $create_invoice_item_sql
	    }
	    db_dml update_invoice_item $update_invoice_item_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading invoice_items:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }

    return $err_return
}


ad_proc -public im_import_project_invoice_map { filename } {
    Import the project_invoice_map  file
} {
    
    set user_id [ad_maybe_redirect_for_registration]
    
    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }
    
    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]
    
    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_project_invoice_map"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	
        set invoice_id [db_string invoice_id "select invoice_id from im_invoices where invoice_nr=:invoice_nr" -default 0]
        set project_id [db_string project "select project_id from im_projects where project_name=:project_name" -default ""]
	
	# -------------------------------------------------------
	# Prepare the DB statements
	#
	
	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	# Check if we have already created the item
        set exists [db_string item_id "select count(*) \ 
                    from acs_rels \  
                    where object_id_two=:invoice_id and object_id_one=:project_id and rel_type = 'relationship'" -default 0]

	if { [catch {

	    if {0 == $exists} {
		# The invoice doesn't exist yet:
		set create_rel_sql "select acs_rel__new(
		null,		-- rel_id
		'relationship', -- rel_type
                :project_id,	-- object_id_one
                :invoice_id,	-- object_id_two
		null,		-- context_id
		null,		-- creation_user
		null		-- creation_ip
           );"
		set rel [db_exec_plsql create_rel $create_rel_sql]
	    }
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading project_company_map:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }

    return $err_return
}



# -------------------------------------------------------
# Payments
# -------------------------------------------------------

ad_proc -public im_import_payments { filename } {
    Import the payments file
} {

    set user_id [ad_maybe_redirect_for_registration]

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_payments"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"

    for {set i 2} {$i < $csv_lines_len} {incr i} {

	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
	ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line || [regexp {^#} $csv_line]} {
	    append err_return "<li>Skipping line '$csv_line'"
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
	set note [ns_urldecode $note]
	# -------------------------------------------------------
	# Transform email and names into IDs
	#

        set cost_id [db_string invoice_id "select cost_id from im_costs where cost_nr=:cost_nr" -default 0]

	set company_id [db_string company "select customer_id from im_costs where cost_id=:cost_id" -default 0]
	set provider_id [db_string provider "select provider_id from im_costs where cost_id=:cost_id" -default 0]

	set payment_status_id [im_import_get_category $payment_status "Intranet Payment Status" ""]
	set payment_type_id [im_import_get_category $payment_type "Intranet Payment Type" ""]
	set sysdate [db_string "get_sysdate" "select sysdate from dual"]
	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_payment_sql "
INSERT INTO im_payments (
        payment_id,
        cost_id,
        company_id,
        provider_id,
	received_date,
	payment_type_id,
        last_modified,
        last_modifying_user,
        modified_ip_address
) values (
	:payment_id,
	:cost_id,
	:company_id,
	:provider_id,
	:received_date,
	:payment_type_id,
	:sysdate,
	:user_id,
	'[ad_conn peeraddr]'
)"


	set update_payment_sql "
UPDATE im_payments
SET
        cost_id              = :cost_id,
        company_id             = :company_id,
        provider_id             = :provider_id,
        received_date           = :received_date,
        start_block             = :start_block,
        payment_type_id         = :payment_type_id,
        payment_status_id       = :payment_status_id,
        amount                  = :amount,
        currency                = :currency,
        note                    = :note,
        last_modified           = :sysdate,
        last_modifying_user     = :user_id,
        modified_ip_address     = '[ad_conn peeraddr]'
WHERE
        payment_id = :payment_id
"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {
	
	    set payment_id [db_string payment_id "select payment_id from im_payments where company_id=:company_id and cost_id=:cost_id and provider_id=:provider_id and received_date=:received_date and start_block=:start_block and payment_type_id=:payment_type_id and currency=:currency" -default 0]

	    if {0 == $payment_id} {
		# The payment doesn't exist yet:
	        set payment_id [db_nextval im_payments_id_seq]
		db_dml payment_create $create_payment_sql
	    }
	    db_dml update_payment $update_payment_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading payments:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }


    # Add relationships between invoices and projects
    # based on the project_id information of the invoice_items.
    # Actually, this is redundand, so we should drop it,
    # but /invoicing/www/new-4 does it, and acs_rel is
    # easy to browse...
    set insert_relations_sql "
declare
     v_rel_id   integer;
begin
     for row in (
        select distinct
                project_id,
                invoice_id
        from
                im_invoice_items i
     ) loop

           v_rel_id := acs_rel.new(
                   object_id_one => row.project_id,
                   object_id_two => row.invoice_id
           );
     end loop;
end;
"
#    db_dml insert_relations $insert_relations_sql

    return $err_return
}

# -------------------------------------------------------
# Investments
# -------------------------------------------------------

ad_proc -public im_import_investments { filename } {
    Import the investments file
} {

    set user_id [ad_maybe_redirect_for_registration]

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_investments"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	    append err_return "<li>Skipping line '$csv_line'"
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

	set investment_id [db_string investment_id "select investment_id from im_investments where investment_name_nr=:investment_name" -default 0]

	set investment_status_id [im_import_get_category $investment_status "Intranet Investment Status" ""]
	set investment_type_id [im_import_get_category $investment_type "Intranet Investment Type" ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_investment_sql "
INSERT INTO im_investment (
        investment_id,
        name,
        investment_status_id,
        investment_type_id
) values (
	:investment_id,
	:investment_name,
	:investment_status_id,
	:investment_type_id
)"


	set update_investment_sql "
UPDATE im_investment
SET
        name                    = :investment_name,
        investment_status_id    = :investment_status_id,
        investment_type__id     = :investment_type_id
WHERE
        investment_id = :investment_id
"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {

	    if {0 == $investment_id} {
		# The investment doesn't exist yet:
	        set investment_id [db_nextval im_investment_id_seq]
		db_dml investment_create $create_investment_sql
	    }
	    db_dml update_investment $update_investment_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading investment:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }

    return $err_return
}

# -------------------------------------------------------
# Target languages
# -------------------------------------------------------

ad_proc -public im_import_target_languages { filename } {
    Import the investments file
} {

    set user_id [ad_maybe_redirect_for_registration]

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_target_languages"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
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
	    append err_return "<li>Skipping line '$csv_line'"
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

	set project_id [db_string project_id "select project_id from im_projects where project_name=:project_name" -default 0]

	set language_id [im_import_get_category $language "Intranet Translation Language" ""]

	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_target_language_sql "
INSERT INTO im_target_languages (
        project_id,
        language_id
) values (
	:project_id,
	:language_id
)"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {
            set exists [db_string "exist project language" "select count(*) \
                         from im_target_languages \
                         where project_id = :project_id and language_id = :language_id" -default 0]
	    if {0 == $exists} {
		# The project language doesn't exist yet:
		db_dml target_language_create $create_target_language_sql
	    }
	    	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading target language:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }

    return $err_return
}



# -------------------------------------------------------
# Prices
# -------------------------------------------------------

ad_proc -public im_import_trans_prices { filename } {
    Import the prices file
} {

    set user_id [ad_maybe_redirect_for_registration]

    set err_return ""
    if {![file readable $filename]} {
	append err_return "Unable to read file '$filename'"
	return $err_return
    }

    set csv_content [exec /bin/cat $filename]
    set csv_lines [split $csv_content "\n"]
    set csv_lines_len [llength $csv_lines]

    # Check whether we accept the specified backup version
    set csv_version_line [lindex $csv_lines 0]
    set csv_version_fields [split $csv_version_line " "]
    set csv_system [lindex $csv_version_fields 0]
    set csv_version [lindex $csv_version_fields 1]
    set csv_table [lindex $csv_version_fields 2]
    set err_msg [im_backup_accepted_version_nr $csv_version]
    if {![string equal $csv_system "po"]} {
	append err_msg "'$csv_system' invalid backup dump<br>"
    }
    if {![string equal $csv_table "im_trans_prices"]} {
	append err_msg "Invalid backup table: '$csv_table'<br>"
    }
    if {"" != $err_msg} {
	append err_return "<li>Error reading '$filename': <br><pre>\n$err_msg</pre>"
	return $err_return
    }

    set csv_header [lindex $csv_lines 1]
    set csv_header_fields [split $csv_header "\""]
    set csv_header_len [llength $csv_header_fields]
    ns_log Notice "csv_header_fields=$csv_header_fields"
    
    for {set i 2} {$i < $csv_lines_len} {incr i} {
	
	set csv_line [string trim [lindex $csv_lines $i]]
	set csv_line_fields [split $csv_line "\""]
	ns_log Notice "csv_line_fields=$csv_line_fields"
	if {"" == $csv_line || [regexp {^#} $csv_line]} {
	    append err_return "<li>Skipping line '$csv_line'"
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

	# Use "" as default values because most of these
	# values are optional.
        #
	set uom_id [im_import_get_category $uom "Intranet UoM" ""]
	set company_id [db_string company "select company_id from im_companies where company_name=:company_name" -default 0]
	set task_type_id [im_import_get_category $task_type "Intranet Project Type" ""]
	set target_language_id [im_import_get_category $target_language "Intranet Translation Language" ""]
	set source_language_id [im_import_get_category $source_language "Intranet Translation Language" ""]
	set subject_area_id  [im_import_get_category $subject_area "Intranet Translation Subject Area" ""]


	# -------------------------------------------------------
	# Prepare the DB statements
	#

	set create_price_sql "
INSERT INTO im_trans_prices (
        price_id,
        uom_id,
        company_id,
        task_type_id,
        target_language_id,
        source_language_id,
        subject_area_id,
        valid_from,
        valid_through,
        currency,
        price
) values (
        :price_id,
        :uom_id,
        :company_id,
        :task_type_id,
        :target_language_id,
        :source_language_id,
        :subject_area_id,
        :valid_from,
        :valid_through,
        :currency,
        :price
)"


	set update_price_sql "
UPDATE im_trans_prices
SET
        uom_id			= :uom_id,
        company_id		= :company_id,
        task_type_id		= :task_type_id,
        target_language_id	= :target_language_id,
        source_language_id	= :source_language_id,
        subject_area_id		= :subject_area_id,
        valid_from		= :valid_from,
        valid_through		= :valid_through,
        currency		= :currency,
        price			= :price
WHERE
        price_id = :price_id
"

	# -------------------------------------------------------
	# Insert into the DB and deal with errors
	#

	if { [catch {
	
	    set price_id [db_string price_id "
select 
	price_id 
from
	im_trans_prices 
where 
	uom_id = :uom_id 
	and company_id = :company_id 
	and task_type_id = :task_type_id 
	and target_language_id = :target_language_id 
	and source_language_id = :source_language_id 
	and subject_area_id = :subject_area_id 
	and currency = :currency
" -default 0]

	    if {0 == $price_id} {
		# The price doesn't exist yet:
	        set price_id [db_nextval im_trans_prices_seq]
		db_dml price_create $create_price_sql
	    }
	    db_dml update_price $update_price_sql
	
	} err_msg] } {
	    ns_log Warning "$err_msg"
	    append err_return "<li>Error loading prices:<br>
	    $csv_line<br><pre>\n$err_msg</pre>"
	}
    }

    return $err_return
}


