# /packages/intranet-core/www/companies/upload-contacts-2.tcl
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
    /intranet/companies/upload-contacts-2.tcl
    Read a .csv-file with header titles exactly matching
    the data model and insert the data into "users" and
    "acs_rels".

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    return_url
    upload_file
} 

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Upload New File/URL"
set page_body "<PRE>\n<A HREF=$return_url>Return to Project Page</A>\n"
set context_bar [ad_context_bar [list "/intranet/cusomers/" "Companies"] "Upload CSV"]

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match company_filename] {
    # couldn't find a match
    set company_filename $upload_file
}

if {[regexp {\.\.} $company_filename]} {
    set error "Filename contains forbidden characters"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}

if {![file readable $tmp_filename]} {
    set err_msg "Unable to read the file '$tmp_filename'. 
Please check the file permissions or contact your system administrator.\n"
    append page_body "\n$err_msg\n"
    doc_return  200 text/html [im_return_template]
    return
}
    
set csv_files_content [exec /bin/cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set csv_files_len [llength $csv_files]
set csv_header [lindex $csv_files 1]
set csv_headers [split $csv_header ";"]

# Check the length of the title line 
set header [string trim [lindex $csv_files 0]]
set header_csv_fields [split $header ";"]
set header_len [llength $header_csv_fields]

append page_body "Title-Length=$header_len\n"
append page_body "\n\n"

for {set i 1} {$i < $csv_files_len} {incr i} {
    set csv_line [string trim [lindex $csv_files $i]]
    set csv_fields [split $csv_line ";"]

    append page_body "$csv_line\n"

    # Preset values, defined by CSV sheet:
    set user_id ""
    set email ""
    set password ""
    set first_names ""
    set last_name ""
    set registration_date ""
    set registration_ip ""
    set user_state ""
    set company_name ""
    set categories ""
    set notes ""

    for {set j 0} {$j < $header_len} {incr j} {
	set var_name [lindex $header_csv_fields $j]
	set var_value [lindex $csv_fields $j]
	set cmd "set $var_name "
	append cmd "\""
	append cmd $var_value
	append cmd "\""
	ns_log Notice "cmd=$cmd"

	if { [catch {	
	    set result [eval $cmd]
	} err_msg] } {
	    append page_body \n<font color=red>$err_msg</font>\n";
        }
	append page_body "set $var_name '$var_value' : $result\n"
    }

    set password $first_names
    ns_log Notice "email=$email"
    ns_log Notice "password=$password"
    ns_log Notice "first_names=$first_names"
    ns_log Notice "last_name=$last_name"
    
    set company_group_id [im_company_group_id]
    set employee_group_id [im_employee_group_id]
    set get_company_id_sql "
		select group_id 
		from user_groups 
		where group_name=:company_name"

    set insert_users_sql "INSERT INTO users (
       user_id, email, password, first_names, last_name, 
       registration_date, registration_ip, user_state
    ) VALUES (
       :user_id, :email, :password, :first_names, :last_name,
       sysdate, '0.0.0.0', 'authorized'
    )"

    set mark_as_company_sql "
INSERT INTO user_group_map VALUES (
    :company_group_id, :user_id, 'member', sysdate, 1, '0.0.0.0'
)"

    set mark_company_employee_sql "
INSERT INTO user_group_map VALUES (
    :company_id, :user_id, 'member', sysdate, 1, '0.0.0.0'
)"

    # set the current users as the primary contact.
    # Works out in the case that there is only one contact,
    # and picks the last user of a specific company if there
    # are severals.
    set update_company_primary_contact "UPDATE im_companies SET 
    primary_contact_id=:user_id where group_id=:company_id"


    if { [catch {
	db_transaction {
	    # make sure the user doesn't exist already (second time
	    # we upload the same CSV...
	    set user_id [db_string exists_sql "select user_id from users where email=:email" -default ""]
	    if {[string equal $user_id ""]} {
		set user_id [db_nextval "user_id_sequence"]
		set company_id [db_string get_company_id $get_company_id_sql -default ""]
		if {[string equal company_id ""]} {
		    append page_body "\n<font color=red>
			  didn't find client '$company_name'
			  </font>\n\n"
		} else {
		    db_dml insert_users_sql $insert_users_sql
		    db_dml mark_as_company_sql $mark_as_company_sql
		    db_dml mark_company_employee_sql $mark_company_employee_sql
		    db_dml update_company_primary_contact $update_company_primary_contact
		}
	    } else {
		append page_body "\nUser $email already exists\n"
	    }
	}
    } err_msg] } {
	append page_body \n<font color=red>$err_msg</font>\n";
    }
}

append page_body "\n<A HREF=$return_url>Return to Project Page</A>\n"
doc_return  200 text/html [im_return_template]
