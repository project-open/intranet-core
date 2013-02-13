# /packages/intranet-core/www/users/upload-users-3.tcl
#
# Copyright (C) 1998-2013 various parties
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

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Expects assignments "Import Columns --> DB fields"
    Performs import/update of user data 

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    { target:multiple,optional "" }
    { security_token }
    { upload_file }
    { locale_numeric }
    { update_hourly_rates_skill_profile:optional }
} 

# ---------------------------------------------------------------
# Local procs 
# ---------------------------------------------------------------

ad_proc -private find_user_id {
    csv_line_fields
    index_list
    db_field_name_list
    user_id_exists_p 
    email_exists_p 
    user_name_exists_p 
    hourly_rate_exists_p
    index_user_id
    index_email
    index_first_names
    index_last_name
    index_username
} { 

    set import_err_msg [lang::message::lookup "" intranet-core.ImportFailedNoUserFound "<strong>Import failed. No data imported.</strong><br>No user found for line: $csv_line_fields"]

    # Check if we can find user based on user_id 
    if { $user_id_exists_p } {
	set user_id [lindex $csv_line_fields $index_user_id]
	if { 0 == [db_string check_email_exists "select count(*) from parties where party_id=:user_id" -default 0] } {
	    ad_return_complaint 1 $import_err_msg
	}
    } elseif { $email_exists_p } {
	# Can user be found based on email? 
	set email [lindex $csv_line_fields [lindex $index_list $index_email]]
	set user_id [db_string get_user_id "select party_id from parties where email=:email" -default 0]
	if { 0 == $user_id } { ad_return_complaint 1 $import_err_msg }
    } elseif { $user_name_exists_p } {
	set username [lindex $csv_line_fields [lindex $index_list $index_username]]
        set user_id [db_string get_user_id "select user_id from users where username=:username" -default 0]
        if { 0 == $user_id } { ad_return_complaint 1 $import_err_msg }
    } else {
	set first_names [lindex $csv_line_fields [lindex $index_list $index_first_names]]
	set last_name [lindex $csv_line_fields $index_last_name]
	set user_id [db_string get_user_id "select person_id from persons where first_names=:first_names and last_name = :last_name" -default 0]
	if { 0 == $user_id } { ad_return_complaint 1 $import_err_msg }
    }
    return $user_id
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title ""
set page_body ""
set context_bar [im_context_bar $page_title]

# Check if user is ADMIN or HR Manager
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p && ![im_profile::member_p -profile_id [im_hr_group_id] -user_id $user_id]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set temp_path_list [parameter::get -package_id [apm_package_id_from_key acs-subsite] -parameter "TmpDir" -default "/tmp"]
set temp_path [lindex $temp_path_list 0]

# ---------------------------------------------------------------
# Extract CSV contents
# ---------------------------------------------------------------

# Load file from tmp folder 
set csv_files_content [fileutil::cat "$temp_path/$security_token/$upload_file"]
set csv_files [split $csv_files_content "\n"]
# set csv_files_len [llength $csv_files]
set separator [im_csv_guess_separator $csv_files]

# Split the header into its fields
set csv_header [string trim [lindex $csv_files 0]]
set csv_header_fields [im_csv_split $csv_header $separator]
# set csv_header_len [llength $csv_header_fields]
set values_list_of_lists [im_csv_get_values $csv_files_content $separator]

# ---------------------------------------------------------------
# Perform separate option_values   
# ---------------------------------------------------------------

set index_list [list]
set db_field_name_list [list]

# ad_return_complaint 1 $target

foreach option_value $target {
    # ns_log NOTICE "intranet-users-upload-users-3: option_value: $option_value" 
    # Sanity Check for '__' in option_value
    if { [string first "__" $option_value ] == -1 } {
	ad_return_complaint 1  [lang::message::lookup "" intranet-core.ErrorImport "Error during import, please contatc your System Adminsitrator"]
	return
    }
    lappend index_list [string range $option_value 0 [expr [string first "__" $option_value]-1]]
    lappend db_field_name_list [string range $option_value [expr [string first "__" $option_value] +2] [string length $option_value] ]  
    ns_log NOTICE "intranet-users-upload-users-3: [string range $option_value 0 [expr [string first "__" $option_value]-1]]"
    ns_log NOTICE "intranet-users-upload-users-3: [string range $option_value [expr [string first "__" $option_value] +2] [string length $option_value]]"
}

# ---------------------------------------------------------------
# Perform validation  
# ---------------------------------------------------------------

# Is there an ID or email field 
set user_id_exists_p 0
set email_exists_p 0
set user_name_exists_p 0
set hourly_rate_exists_p 0

# ad_return_complaint 1 $db_field_name_list

if { [lsearch -exact $db_field_name_list "user_id"] != -1 } { set user_id_exists_p 1 }
if { [lsearch -exact $db_field_name_list "email"] != -1 } { set email_exists_p 1 }
if { [lsearch -exact $db_field_name_list "username"] != -1 } { set user_name_exists_p 1 }
if { [lsearch -exact $db_field_name_list "hourly_rate"] != -1 } { set hourly_rate_exists_p 1 }

# Index user_id 
set index_user_id [lsearch -exact $db_field_name_list "user_id"]
# Index user_id 
set index_email [lsearch -exact $db_field_name_list "email"]
# Index First Names
set index_first_names [lsearch -exact $db_field_name_list "first_names"]
# Index Last Name
set index_last_name [lsearch -exact $db_field_name_list "last_name"]
# Index Last Name
set index_username [lsearch -exact $db_field_name_list "username"]
# Index Last Name
set index_hourly_rate [lsearch -exact $db_field_name_list "hourly_rate"]

ns_log NOTICE "intranet-users-upload-users-3: [string range $option_value [expr [string first "__" $option_value] +2] [string length $option_value]]"

set linecount 0

foreach csv_line_fields $values_list_of_lists {

    set import_err_msg "Import failed. No user found for line: $csv_line_fields"
    
    # Verify if user_id can be found, 
    set user_id_ [find_user_id \
		 $csv_line_fields \
		 $index_list \
		 $db_field_name_list \
		 $user_id_exists_p \
		 $email_exists_p \
		 $user_name_exists_p \
		 $hourly_rate_exists_p \
		 $index_user_id $index_email \
		 $index_first_names \
		 $index_last_name \
		 $index_username]

    if { $hourly_rate_exists_p } {
        set hourly_rate [lindex $csv_line_fields [lindex $index_list $index_hourly_rate]]
        if { "de_DE" == $locale_numeric } {
            set hourly_rate [lc_parse_number $hourly_rate de_DE]
        } else {
            set hourly_rate [lc_parse_number $hourly_rate en_US]
        }
	# Check if value found has right format 
	if { ![string is double -strict $hourly_rate] } {
		ad_return_complaint 1 "Import failed. Found non-numeric value for hourly rate: $csv_line_fields. Please make sure that numeric values are provided as selected in 1st step."
	}
    }    
}

# ---------------------------------------------------------------
# Perform Import
# ---------------------------------------------------------------

set protocol_txt "<strong>[lang::message::lookup "" intranet-core.ImportProtocol "Import Protocol"]:</strong><br><br>"
append protocol_txt "<ul>" 

foreach csv_line_fields $values_list_of_lists {

    set user_id [find_user_id \
		 $csv_line_fields \
		 $index_list \
		 $db_field_name_list \
		 $user_id_exists_p \
		 $email_exists_p \
		 $user_name_exists_p \
		 $hourly_rate_exists_p \
		 $index_user_id $index_email \
		 $index_first_names \
		 $index_last_name \
		 $index_username]
    
    set user_name_from_id [im_name_from_user_id $user_id]

    if { $hourly_rate_exists_p } {
	set hourly_rate [lindex $csv_line_fields [lindex $index_list $index_hourly_rate]]
	if { [catch {
		set hourly_rate [lc_parse_number $hourly_rate $locale_numeric] 
	    } errmsg]} {
      		ad_return_complaint 1 "<li>Error converting numbers. Please make sure you have choosen the right format for numbers when uploading File.</li>"
	}

	if {[catch {
      		db_dml employee_information "
		        update im_employees set
       		        hourly_cost = :hourly_rate
	            where
       		        employee_id = :user_id
    	"
    	} errmsg]} {
      		ad_return_complaint 1 "<li>Error updating user - employee information: <pre>$errmsg</pre> Please correct the problem and try again or contact your System Administrator</li>"
    	}

	if { [info exists update_hourly_rates_skill_profile] && $user_name_exists_p } {
	    set username [lindex $csv_line_fields [lindex $index_list $index_username]]
	    # Get skill role Id 
	    set skill_role_id [im_id_from_category $username "Intranet Skill Role"]
	    if { 0 != $skill_role_id  } {
		if {[catch {
		    db_dml employee_information "
		        update im_employees set
       		        	hourly_cost = :hourly_rate
	            	where
       		        employee_id in (select user_id from users where skill_role_id = :skill_role_id) 
    		    "
	    	} errmsg]} {
		    append protocol_txt "<li>Error updating hourly cost for user(s) with Skill Profile: $username. Please check log file for additional information.</li>"
		}

		# if {[catch {
		#	db_foreach col "select employee_id from im_employees e where skill_role_id = :skill_role_id" {
		#	append protocol_txt "<li>Updated Hourly Rate (Skill Profile: $username) of user: <a href='/intranet/users/view?user_id=$employee_id'>$user_name_from_id</a></li>"		    
		#    }
		# } errmsg] } {}

	    } else {
		    append protocol_txt "<li>Error updating Hourly Rate based on User Skill Profile for user <a href='/intranet/users/view?user_id=$user_id'>$user_name_from_id</a>: 
						No Category Entry found for Skill Profile: $username </li>"
	    }
	} else {
	    if { !$user_name_exists_p } {
		    append protocol_txt "<li>Error updating Hourly Rate for user <a href='/intranet/users/view?user_id=$user_id'>$user_name_from_id</a> based on User Skill Profile: No Skill Profile '$username' found.</li>"
	    } 
	}
    }; # hourly_rate_exists_p
    append protocol_txt "<li>Updated user: <a href='/intranet/users/view?user_id=$user_id'>$user_name_from_id</a>, new hourly rate is: $hourly_rate;</li> "
}

append protocol_txt "<li>[lang::message::lookup "" intranet-core.ImportFinished "Import finsihed"]</li>"
append protocol_txt "</ul>" 


# ------------------------------------------------------------
# Render Report Footer
# ns_write $protocol_txt
set page_title [lang::message::lookup "" intranet-core.ImportProtocol "Protocol"]