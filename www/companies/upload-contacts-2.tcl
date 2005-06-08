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
    profile_id
} 

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Upload New File/URL"
set page_body ""
set context_bar [im_context_bar [list "/intranet/cusomers/" "Companies"] "Upload CSV"]


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
    ad_return_complaint 1 "Filename contains forbidden characters"
}

if {![file readable $tmp_filename]} {
    set err_msg "Unable to read the file '$tmp_filename'. 
Please check the file permissions or contact your system administrator.\n"
    append page_body "\n$err_msg\n"
    doc_return  200 text/html [im_return_template]
    return
}

set csv_files_content [fileutil::cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set csv_files_len [llength $csv_files]


set separator ";"
ns_log Notice "upload-companies-2: trying separator=$separator"


# Split the header into its fields
set csv_header [string trim [lindex $csv_files 0]]
set csv_header_fields [im_csv_split $csv_header $separator]
set csv_header_len [llength $csv_header_fields]


if {$csv_header_len <= 1} {
    # Probably got the wrong separator
    set separator ","
    ns_log Notice "upload-companies-2: changing to separator=$separator"
    set csv_header_fields [im_csv_split $csv_header $separator]
    set csv_header_len [llength $csv_header_fields]
}

for {set i 1} {$i < $csv_files_len} {incr i} {
    set csv_line [string trim [lindex $csv_files $i]]
    set csv_line_fields [im_csv_split $csv_line $separator]

    if {"" == $csv_line} {
	ns_log Notice "skipping empty line"
	continue
    }

    # Preset values, defined by CSV sheet:
    set user_id ""
    set email ""
    set password ""
    set last_name ""
    set registration_date ""
    set registration_ip ""
    set user_state ""
    set company_name ""

    set title ""
    set first_name ""
    set middle_name ""
    set last_name ""
    set suffix ""
    set company ""
    set department ""
    set job_title ""
    set business_street ""
    set business_street_2 ""
    set business_street_3 ""
    set business_city ""
    set business_state ""
    set business_postal_code ""
    set business_country ""
    set home_street ""
    set home_street_2 ""
    set home_street_3 ""
    set home_city ""
    set home_state ""
    set home_postal_code ""
    set home_country ""
    set other_street ""
    set other_street_2 ""
    set other_street_3 ""
    set other_city ""
    set other_state ""
    set other_postal_code ""
    set other_country ""
    set assistants_phone ""
    set business_fax ""
    set business_phone ""
    set business_phone_2 ""
    set callback ""
    set car_phone ""
    set company_main_phone ""
    set home_fax ""
    set home_phone ""
    set home_phone_2 ""
    set isdn ""
    set mobile_phone ""
    set other_fax ""
    set other_phone ""
    set pager ""
    set primary_phone ""
    set radio_phone ""
    set tty_tdd_phone ""
    set telex ""
    set account ""
    set anniversary ""
    set assistants_name ""
    set billing_information ""
    set birthday ""
    set categories ""
    set children ""
    set directory_server ""
    set e_mail_address ""
    set e_mail_display_name ""
    set e_mail_2_address ""
    set e_mail_2_display_name ""
    set e_mail_3_address ""
    set e_mail_3_display_name ""
    set gender ""
    set government_id_number ""
    set hobby ""
    set initials ""
    set internet_free_busy ""
    set keywords ""
    set language ""
    set location ""
    set managers_name ""
    set mileage ""
    set note ""
    set office_location ""
    set organizational_id_number ""
    set po_box ""
    set priority ""
    set private ""
    set profession ""
    set referred_by ""
    set sensitivity ""
    set spouse ""
    set user_1 ""
    set user_2 ""
    set user_3 ""
    set user_4 ""
    set web_page ""

    # -------------------------------------------------------
    # Extract variables from the CSV file
    #

    set var_name_list [list]
    for {set j 0} {$j < $csv_header_len} {incr j} {

	set var_name [string trim [lindex $csv_header_fields $j]]
	set var_name [string tolower $var_name]
	set var_name [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $var_name]
	lappend var_name_list $var_name
	ns_log notice "upload-contacts-2: varname([lindex $csv_header_fields $j]) = $var_name"

	set var_value [string trim [lindex $csv_line_fields $j]]
	if {[string equal "NULL" $var_value]} { set var_value ""}
	
	set cmd "set $var_name \"$var_value\""
	ns_log Notice "upload-contacts-2: cmd=$cmd"
	set result [eval $cmd]
    }



    # Set additional variables not in Outlook
    set password $first_name
    set password_confirm $password
    set screen_name [string tolower "$first_name $last_name"]
    regsub -all {[^A-Za-z0-9_]} $screen_name "_" username
    set secret_question ""
    set secret_answer ""


    # Check if the user already exists
    set found_n [db_string person_count "select count(*) from persons where lower(first_names) = lower(:first_name) and lower(last_name) = lower(:last_name)"]

    if {$found_n > 1} {
	append page_body "<li>'$first_name $last_name': Skipping, because we have found $found_n users with this name.\n"
	continue
    }


    # -------------------------------------------------------
    # Create a new user if necessary
    #
    if {0 == $found_n} {

	# Create a new user
	set user_id [db_nextval acs_object_id_seq]
	append page_body "<li>'$first_name $last_name': Creating a new user with ID \#$user_id\n"

	array set creation_info [auth::create_user \
                                         -user_id $user_id \
                                         -verify_password_confirm \
                                         -username $username \
                                         -email $e_mail_address \
                                         -first_names $first_name \
                                         -last_name $last_name \
                                         -screen_name $screen_name \
                                         -password $password \
                                         -password_confirm $password_confirm \
                                         -url $web_page \
                                         -secret_question $secret_question \
				 -secret_answer $secret_answer]


	# Add the user to the "Registered Users" group, because
	# (s)he would get strange problems otherwise
	set registered_users [db_string registered_users "select object_id from acs_magic_objects where name='registered_users'"]
#	relation_add -member_state "approved" "membership_rel" $registered_users $user_id

	# Add a users_contact record to the user since the 3.0 PostgreSQL
	# port, because we have dropped the outer join with it...
	db_dml add_users_contact "insert into users_contact (user_id) values (:user_id)"

	if {[db_table_exists im_employees]} {
	    # Add a im_employees record to the user since the 3.0 PostgreSQL
	    # port, because we have dropped the outer join with it...
	    # Simply add the record to all users, even it they are not employees...
	    db_dml add_im_employees "insert into im_employees (employee_id) values (:user_id)"
	}

    }

    # -------------------------------------------------------
    # Update the user's information 
    # Execute this no matter whether it's a new or an existing user
    #

    set user_id [db_string person_id "select person_id from persons where lower(first_names) = lower(:first_name) and lower(last_name) = lower(:last_name)"]
    append page_body "<li>'$first_name $last_name': Updating user\n"

    set auth [auth::get_register_authority]
    set user_data [list]

    person::update \
                -person_id $user_id \
                -first_names $first_name \
                -last_name $last_name

    party::update \
                -party_id $user_id \
                -url $web_page \
                -email $e_mail_address

    acs_user::update \
                -user_id $user_id \
                -screen_name $screen_name

    if {"" != $other_street} {append note "other_street = $other_street\n" }
    if {"" != $other_street_2} {append note "other_street_2 = $other_street_2\n" }
    if {"" != $other_street_3} {append note "other_street_3 = $other_street_3\n" }
    if {"" != $other_city} {append note "other_city = $other_city\n" }
    if {"" != $other_state} {append note "other_state = $other_state\n" }
    if {"" != $other_postal_code} {append note "other_postal_code = $other_postal_code\n" }
    if {"" != $other_country} {append note "other_country = $other_country\n" }

    if {"" != $assistants_phone} {append note "assistants_phone = $assistants_phone\n" }
    if {"" != $title} {append note "title = $title\n" }
    if {"" != $middle_name} {append note "middle_name = $middle_name\n" }
    if {"" != $suffix} {append note "suffix = $suffix\n" }
    if {"" != $company} {append note "company = $company\n" }
    if {"" != $department} {append note "department = $department\n" }
    if {"" != $job_title} {append note "job_title = $job_title\n" }
    if {"" != $business_phone_2} {append note "business_phone_2 = $business_phone_2\n" }
    if {"" != $callback} {append note "callback = $callback\n" }
    if {"" != $car_phone} {append note "car_phone = $car_phone\n" }
    if {"" != $company_main_phone} {append note "company_main_phone = $company_main_phone\n" }
    if {"" != $home_fax} {append note "home_fax = $home_fax\n" }
    if {"" != $home_phone_2} {append note "home_phone_2 = $home_phone_2\n" }
    if {"" != $isdn} {append note "isdn = $isdn\n" }

    if {"" != $other_fax} {append note "other_fax = $other_fax\n" }
    if {"" != $other_phone} {append note "other_phone = $other_phone\n" }
    if {"" != $primary_phone} {append note "primary_phone = $primary_phone\n" }
    if {"" != $radio_phone} {append note "radio_phone = $radio_phone\n" }
    if {"" != $tty_tdd_phone} {append note "tty_tdd_phone = $tty_tdd_phone\n" }
    if {"" != $telex} {append note "telex = $telex\n" }
    if {"" != $account} {append note "account = $account\n" }
    if {"" != $anniversary} {append note "anniversary = $anniversary\n" }
    if {"" != $assistants_name} {append note "assistants_name = $assistants_name\n" }

    if {"" != $billing_information} {append note "billing_information = $billing_information\n" }
    if {"" != $birthday} {append note "birthday = $birthday\n" }
    if {"" != $categories} {append note "categories = $categories\n" }
    if {"" != $children} {append note "children = $children\n" }
    if {"" != $directory_server} {append note "directory_server = $directory_server\n" }


    if {"" != $e_mail_2_address} {append note "e_mail_2_address = $e_mail_2_address\n" }
    if {"" != $e_mail_3_address} {append note "e_mail_3_address = $e_mail_3_address\n" }
    if {"" != $gender} {append note "gender = $gender\n" }
    if {"" != $government_id_number} {append note "government_id_number = $government_id_number\n" }
    if {"" != $hobby} {append note "hobby = $hobby\n" }
    if {"" != $initials} {append note "initials = $initials\n" }
    if {"" != $internet_free_busy} {append note "internet_free_busy = $internet_free_busy\n" }
    if {"" != $keywords} {append note "keywords = $keywords\n" }
    if {"" != $language} {append note "language = $language\n" }
    if {"" != $location} {append note "location = $location\n" }
    if {"" != $managers_name} {append note "managers_name = $managers_name\n" }
    if {"" != $mileage} {append note "mileage = $mileage\n" }
    if {"" != $office_location} {append note "office_location = $office_location\n" }
    if {"" != $organizational_id_number} {append note "organizational_id_number = $organizational_id_number\n" }
    if {"" != $po_box} {append note "po_box = $po_box\n" }
    if {"" != $priority} {append note "priority = $priority\n" }
    if {"" != $private} {append note "private = $private\n" }
    if {"" != $profession} {append note "profession = $profession\n" }
    if {"" != $referred_by} {append note "referred_by = $referred_by\n" }
    if {"" != $sensitivity} {append note "sensitivity = $sensitivity\n" }
    if {"" != $spouse} {append note "spouse = $spouse\n" }
    if {"" != $user_1} {append note "user_1 = $user_1\n" }
    if {"" != $user_2} {append note "user_2 = $user_2\n" }
    if {"" != $user_3} {append note "user_3 = $user_3\n" }
    if {"" != $user_4} {append note "user_4 = $user_4\n" }
    if {"" != $web_page} {append note "web_page = $web_page\n" }


    # Get the country code
    set home_country_code [db_string country_code "select iso from country_codes where lower(country_name) = lower(:home_country)" -default ""]
    set business_country_code [db_string country_code "select iso from country_codes where lower(country_name) = lower(:business_country)" -default ""]
    set other_country_code [db_string country_code "select iso from country_codes where lower(country_name) = lower(:other_country)" -default ""]
    

    db_dml update_users_contact "
    update users_contact set 
	home_phone = :home_phone,
	work_phone = :business_phone,
	cell_phone = :mobile_phone,
	pager = :pager,
	fax = :business_fax,
	ha_line1 = :home_street,
	ha_line2 = trim(:home_street_2 || ' ' || :home_street_3),
	ha_city = :home_city,
	ha_state = :home_state,
	ha_postal_code = :home_postal_code,
	ha_country_code = :home_country_code,
	wa_line1 = :business_street,
	wa_line2 = trim(:business_street_2 || ' ' || :business_street_3),
	wa_city = :business_city,
	wa_state = :business_state,
	wa_postal_code = :business_postal_code,
	wa_country_code = :business_country_code,
	note = :note
    where
	user_id = :user_id	
"

#	aim_screen_name      
#	msn_screen_name      
#	icq_number           
#	current_information  

    # -------------------------------------------------------
    # Deal with the users's company
    #

    if {"" != $company} {
	set company_id [db_string find_company "select company_id from im_companies where lower(company_name) = lower(:company)" -default 0]
	
	if {0 != $company_id} {
	
	    set relationship_count [db_string relationship_count "select count(*) from acs_rels where object_id_one = :company_id and object_id_two = :user_id"]
	    if {0 == $relationship_count} {

		append page_body "<li>'$first_name $last_name': Adding as member to '$company'\n"
		im_biz_object_add_role $user_id $company_id [im_biz_object_role_full_member]
	    } else {
		append page_body "<li>'$first_name $last_name': Is already a member of '$company'\n"
	    }

	} else {
	    append page_body "<li>'$first_name $last_name': Unable to find the users' company '$company'\n"
	}
    }

    # -------------------------------------------------------
    # Deal with the users's profile membership
    #
    if {0 != $profile_id} {
        # Make the user a member of the group (=profile)
        ns_log Notice "upload-contacts-2: => relation_add $profile_id $user_id"
        set rel_id [relation_add -member_state "approved" "membership_rel" $profile_id $user_id]
        db_dml update_relation "update membership_rels set member_state='approved' where rel_id=:rel_id"
        append page_body "<li>'$first_name $last_name': Added to group '$profile_id'.\n"
    } else {
        append page_body "<li>'$first_name $last_name': Not adding the user to any group.\n"
    }


}

