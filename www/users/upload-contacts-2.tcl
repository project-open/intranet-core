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

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------


ad_page_contract {
    /intranet/companies/upload-contacts-2.tcl
    Read a .csv-file with header titles exactly matching
    the data model and insert the data into "users" and
    "acs_rels".

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com

    @param transformation_key Determins a number of additional fields 
	   to import
    @param create_dummy_email Set this for example to "@nowhere.com" 
	   in order to create dummy emails for users without email.

} {
    return_url
    upload_file
    profile_id
    { transformation_key "" }
    { create_dummy_email "" }
} 


# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Contacts CSV"
set page_body ""
set context_bar [im_context_bar $page_title]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $profile_id || 0 == $profile_id} {
    ad_return_complaint 1 "Profile not set:<br>
    You have not specified a value for Profile"
    return
}



# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

# Describes how Excel attributes are loaded into DynFields
# Format:
#       1. Excel Column Name
#       2. Table Column
#       3. Transformation Function

set dynfield_trans_list {}

# Define some hardcoded transformations until we've finished the
# maintenance screens for database-configured transformations...
switch $transformation_key {
    reinisch_freelance_contacts {
        set dynfield_trans_list {
            {"user1"			"valoration"		"im_transform_trim"}
	    {"Idioma materno"		"idioma_materno"	"im_transform_trim"}

	    {"Idiomas1_Origen"		"idiomas1_origen"	"im_transform_trim"}
	    {"Idiomas1_Destino"		"idiomas1_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 1"	"idiomas1_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas2_Origen"		"idiomas2_origen"	"im_transform_trim"}
	    {"Idiomas2_Destino"		"idiomas2_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 2"	"idiomas2_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas3_Origen"		"idiomas3_origen"	"im_transform_trim"}
	    {"Idiomas3_Destino"		"idiomas3_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 3"	"idiomas3_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas4_Origen"		"idiomas4_origen"	"im_transform_trim"}
	    {"Idiomas4_Destino"		"idiomas4_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 4"	"idiomas4_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas5_Origen"		"idiomas5_origen"	"im_transform_trim"}
	    {"Idiomas5_Destino"		"idiomas5_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 5"	"idiomas5_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas6_Origen"		"idiomas6_origen"	"im_transform_trim"}
	    {"Idiomas6_Destino"		"idiomas6_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 6"	"idiomas6_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas7_Origen"		"idiomas7_origen"	"im_transform_trim"}
	    {"Idiomas7_Destino"		"idiomas7_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 7"	"idiomas7_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas8_Origen"		"idiomas8_origen"	"im_transform_trim"}
	    {"Idiomas8_Destino"		"idiomas8_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 8"	"idiomas8_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas9_Origen"		"idiomas9_origen"	"im_transform_trim"}
	    {"Idiomas9_Destino"		"idiomas9_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 9"	"idiomas9_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas10_Origen"		"idiomas10_origen"	"im_transform_trim"}
	    {"Idiomas10_Destino"	"idiomas10_destino"	"im_transform_trim"}
	    {"Tarifas/palabra 10"	"idiomas10_tarifa"	"im_transform_komma2dot"}

	    {"Idiomas11_Origen"		"idiomas11_origen"	"im_transform_trim"}
	    {"Idiomas11_Destino"	"idiomas11_destino"	"im_transform_trim"}

	    {"Idiomas12_Origen"		"idiomas12_origen"	"im_transform_trim"}
	    {"Idiomas12_Destino"	"idiomas12_destino"	"im_transform_trim"}
        }
    }
}


# ---------------------------------------------------------------
# Get the uploaded file
# ---------------------------------------------------------------

# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-contacts-2.tcl" -value $tmp_filename
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
    ad_return_complaint 1 "Unable to read the file '$tmp_filename'. 
Please check the file permissions or contact your system administrator.\n"
    ad_script_abort
}


# ---------------------------------------------------------------
# Extract CSV contents
# ---------------------------------------------------------------

set csv_files_content [fileutil::cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set csv_files_len [llength $csv_files]

set separator [im_csv_guess_separator $csv_files]

# Split the header into its fields
set csv_header [string trim [lindex $csv_files 0]]
set csv_header_fields [im_csv_split $csv_header $separator]
set csv_header_len [llength $csv_header_fields]
set values_list_of_lists [im_csv_get_values $csv_files_content $separator]


# ---------------------------------------------------------------
# Render Page Header
# ---------------------------------------------------------------

# This page is a "streaming page" without .adp template,
# because this page can become very, very long and take
# quite some time.

ad_return_top_of_page "
        [im_header]
        [im_navbar]
"


# ---------------------------------------------------------------
# Start parsing the CSV
# ---------------------------------------------------------------


set linecount 0
foreach csv_line_fields $values_list_of_lists {
    incr linecount
    
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
    set supervisor ""
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
    set notes ""
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
    set availability ""


    # -------------------------------------------------------
    # Extract variables from the CSV file
    # Loop through all columns of the CSV file and set 
    # local variables according to the column header (1st row).

    set var_name_list [list]
    set pretty_field_string ""
    set pretty_field_header ""
    set pretty_field_body ""
    for {set j 0} {$j < $csv_header_len} {incr j} {

	set var_name [string trim [lindex $csv_header_fields $j]]
	set var_name [string tolower $var_name]
	set var_name [string map -nocase {" " "_" "\"" "" "'" "" "/" "_" "-" "_"} $var_name]
	set var_name [im_mangle_unicode_accents $var_name]

	# Deal with German Outlook exports
	set var_name [im_upload_cvs_translate_varname $var_name]

	lappend var_name_list $var_name

	set var_value [string trim [lindex $csv_line_fields $j]]
	set var_value [string map -nocase {"\"" "" "\{" "(" "\}" ")" "\[" "(" "\]" ")"} $var_value]
	if {[string equal "NULL" $var_value]} { set var_value ""}
	append pretty_field_header "<td>$var_name</td>\n"
	append pretty_field_body "<td>$var_value</td>\n"

#	append pretty_field_string "$var_name\t\t$var_value\n"
#	ns_log notice "upload-contacts: [lindex $csv_header_fields $j] => $var_name => $var_value"	

	set cmd "set $var_name \"$var_value\""
	ns_log Notice "upload-contacts-2: cmd=$cmd"
	set result [eval $cmd]
    }

    if {"" != $pretty_field_header} {
	set pretty_field_string "
	    <table border=1 cellspacing=0 cellpadding=0>
	    <tr>$pretty_field_header</tr>
	    <tr>$pretty_field_body</tr>
	    </table>
        "
    }

    if {"" == $first_name} {
	ns_write "<li>Error: We have found an empty 'First Name' in line $linecount.<br>
        Error: We can not add users with an empty first name, Please correct the CSV file.
        <br><pre>$pretty_field_string</pre>"
	continue
    }

    if {"" == $last_name} {
	ns_write "<li>Error: We have found an empty 'Last Name' in line $linecount.<br>
        We can not add users with an empty last name. Please correct the CSV file.<br>
        <pre>$pretty_field_string</pre>"
	continue
    }

    # Deal with Outlook Email format "First Last (user@company.com)"
    if {[regexp {[a-z0-9A-Z\ \-\_]+\((.+)\)} $e_mail_address match email]} { set e_mail_address $email }

    # Create a dummy email if there was something set in the parameter:
    if {"" == $e_mail_address && "" != $create_dummy_email} {
        regsub -all { } $first_name "" first_name_nospace
        regsub -all { } $last_name "" last_name_nospace
        set e_mail_address "${first_name_nospace}.${last_name_nospace}${create_dummy_email}"
    }

    if {"" == $e_mail_address} {
	ns_write "<li>Error: We have found an empty 'e_mail_address' in line $linecount.<br>
        We can not add users with an empty email. Please correct the CSV file.<br>
        <pre>$pretty_field_string</pre>"
	continue
    }

    # Set additional variables not in Outlook
    set password $first_name
    set password_confirm $password
    set screen_name [string tolower "$first_name $last_name"]
    regsub -all {[^A-Za-z0-9_]} $screen_name "_" username
    set secret_question ""
    set secret_answer ""

    # Check if the email already exists
    # Emails are unique.
    set found_n 0
    set user_id [db_string check_email_exists "select party_id from parties where lower(email) = lower(:e_mail_address)" -default 0]


    # Add a "http://" before the WebPage in order to satisfy some
    # strange constraints in the auth::create_user procedure...
    if {"" != $web_page && ![regexp {http:} $web_page]} {
	set web_page "http://$web_page"
    }


    set userinfo "email = $e_mail_address, "
    if {"" != $title} {append userinfo "title = $title, " }
    append userinfo "first_name = $first_name, "
    if {"" != $middle_name} {append userinfo "middle_name = $middle_name, " }
    append userinfo "last_name = $last_name, "
    if {"" != $suffix} {append userinfo "suffix = $suffix, " }
    append userinfo "username = $username, "
    append userinfo "screen_name = $screen_name, "
    if {"" != $web_page} {append userinfo "web_page = $web_page, " }
    if {"" != $company} {append userinfo "company = $company, " }
    if {"" != $company_name} {append userinfo "company_name = $company_name, " }
    if {"" != $department} {append userinfo "department = $department, " }
    if {"" != $job_title} {append userinfo "job_title = $job_title, " }
    append userinfo "user_id = $user_id"

    ns_write "<li>$userinfo\n"


    if {0 == $user_id} {

	# Checking for equal first+last name.
	# Names are not unique...
	set found_n [db_string person_count "
		select count(*) 
		from persons 
		where 	lower(first_names) = lower(:first_name) 
			and lower(last_name) = lower(:last_name)
	"]
	if {$found_n > 1} {
	    ns_write "<li>'$first_name $last_name': 
	    Skipping, because we have found $found_n users with this name.\n"
	    continue
	}


	# Checking for equal screen name.
	set found_screen_n [db_string person_count "
		select count(*) 
		from users 
		where lower(screen_name) = lower(:screen_name) 
	"]
	if {$found_screen_n > 0} {
	    ns_write "<li>'$screen_name': 
	    Skipping, because we have found another user with this screen name.\n"
	    continue
	}


	if {1 == $found_n} {
	    set user_id [db_string person_id "select person_id from persons where lower(first_names) = lower(:first_name) and lower(last_name) = lower(:last_name)"]
	}
    }

    ns_write $pretty_field_string


    # -------------------------------------------------------
    # Create a new user if necessary
    #
    if {0 == $user_id} {

	# Create a new user
	set user_id [db_nextval acs_object_id_seq]
	ns_write "<li>'$first_name $last_name': Creating a new user with ID \#$user_id\n"

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

	ns_log Notice "upload-contacts-2: creation_status=$creation_info(creation_status)"
        switch $creation_info(creation_status) {
            ok {
                # Continue below
            }
            default {
                # Adding the error to the first element, but only
                # if there are no element messages
                if { [llength $creation_info(element_messages)] == 0 } {
                    array set reg_elms [auth::get_registration_elements]
                    set first_elm [lindex [concat $reg_elms(required) $reg_elms(optional)] 0]
		    ns_write "<li>'$first_name $last_name': Error creating new user: <br>
                    $creation_info(creation_message)\n"
                }

                # Element messages
                foreach { elm_name elm_error } $creation_info(element_messages) {
		    ns_write "<li>'$first_name $last_name': Error creating new user: <br>
                    $elm_name $elm_error\n"
                }
                continue
            }
        }



	# Add the user to the "Registered Users" group, because
	# (s)he would get strange problems otherwise
	set registered_users [db_string registered_users "select object_id from acs_magic_objects where name='registered_users'"]
	relation_add -member_state "approved" "membership_rel" $registered_users $user_id

	if {[im_table_exists im_employees]} {
	    # Add a im_employees record to the user since the 3.0 PostgreSQL
	    # port, because we have dropped the outer join with it...
	    # Simply add the record to all users, even it they are not employees...
	    set employee_found [db_string employee_found "select count(*) from im_employees where employee_id = :user_id"]
	    if {!$employee_found} {
		db_dml add_im_employees "insert into im_employees (employee_id) values (:user_id)"
	    }
	}
    }

    # -------------------------------------------------------
    # Update the user's information 
    # Execute this no matter whether it's a new or an existing user
    #

    ns_write "<li>
	'$first_name $last_name': Updating user ...<br>
    "
    
    # Add a users_contact record to the user since the 3.0 PostgreSQL
    # port, because we have dropped the outer join with it...
    # Execute this separately from creating a new user because there
    # may still be users without the users_contact...
    set users_contact_count [db_string users_contact_count "select count(*) from users_contact where user_id = :user_id"]
    if {0 == $users_contact_count} {
	db_dml add_users_contact "insert into users_contact (user_id) values (:user_id)"
    }

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
                
	# Checking for equal screen name.
	set found_screen_n [db_string person_count "
		select count(*) 
		from users 
		where lower(screen_name) = lower(:screen_name) and user_id != :user_id
	"]
	if {$found_screen_n > 0} {
	    ns_write "
	    Skipping, because we have found another user with this screen name '$screen_name'.\n"
	    continue
	}

    acs_user::update \
                -user_id $user_id \
                -screen_name $screen_name

    if {"" != $notes} {append note "$notes\n" }
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
    if {"" != $anniversary && "0/0/00" != $anniversary} {append note "anniversary = $anniversary\n" }
    if {"" != $assistants_name} {append note "assistants_name = $assistants_name\n" }

    if {"" != $billing_information} {append note "billing_information = $billing_information\n" }
    if {"" != $birthday && "0/0/00" != $birthday} {append note "birthday = $birthday\n" }
    if {"" != $categories} {append note "categories = $categories\n" }
    if {"" != $children} {append note "children = $children\n" }
    if {"" != $directory_server} {append note "directory_server = $directory_server\n" }


    if {"" != $e_mail_2_address} {append note "e_mail_2_address = $e_mail_2_address\n" }
    if {"" != $e_mail_3_address} {append note "e_mail_3_address = $e_mail_3_address\n" }
    if {"" != $gender && "Unspecified" != $gender} {append note "gender = $gender\n" }
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
    if {"" != $priority && "Normal" != $priority} {append note "priority = $priority\n" }
    if {"" != $private && "False" != $private} {append note "private = $private\n" }
    if {"" != $profession} {append note "profession = $profession\n" }
    if {"" != $referred_by} {append note "referred_by = $referred_by\n" }
    if {"" != $sensitivity && "Normal" != $sensitivity} {append note "sensitivity = $sensitivity\n" }
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
    
    ns_log Notice "Updating users_contact: 
    	home_phone = $home_phone,
	work_phone = $business_phone,
	cell_phone = $mobile_phone,
	pager = $pager,
	fax = $business_fax,
	ha_line1 = $home_street,
	ha_line2 = $home_street_2 $home_street_3
	ha_city = $home_city,
	ha_state = $home_state,
	ha_postal_code = $home_postal_code,
	ha_country_code = $home_country_code,
	wa_line1 = $business_street,
	wa_line2 = $business_street_2 $business_street_3,
	wa_city = $business_city,
	wa_state = $business_state,
	wa_postal_code = $business_postal_code,
	wa_country_code = $business_country_code,
	note = $note"


    if {[catch {

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

    } errmsg]} {
	ns_write "<li>Error updating user \#$user_id:<br><pre>$errmsg</pre>"
    }

    # -------------------------------------------------------
    # Employee information 
    #

    if { "" != $availability } {
	    if {[catch {
        	db_dml employee_information "
	            update im_employees set
        	        availability = :availability
	            where
        	        employee_id = :user_id
	        "
	    } errmsg]} {
        	ns_write "<li>Error updating user - employee information \\#$user_id:<br><pre>$errmsg</pre>"
	    }
    }

    # Set supervisor

    if { "" != $supervisor } {
	set supervisor_user_id [im_gp_find_person_for_name -name $supervisor -email $supervisor]
	if { "" != $supervisor_user_id } {
	    if {[catch {
		db_dml employee_information "
	            update im_employees set
        	        supervisor_id = $supervisor_user_id
	            where
        	        employee_id = :user_id
        	"
		} errmsg]} {
        		ns_write "<li>Error updating user - employee information \\\#$user_id:<br><pre>$errmsg</pre>"
		}	
	}
    }

    # -------------------------------------------------------
    # Deal with the users's company
    #

    if {"" != $company} {
	set company_id [db_string find_company "select company_id from im_companies where lower(company_name) = lower(:company)" -default 0]
	
	if {0 != $company_id} {
	
	    set relationship_count [db_string relationship_count "select count(*) from acs_rels where object_id_one = :company_id and object_id_two = :user_id"]
	    if {0 == $relationship_count} {

		ns_write "<li>'$first_name $last_name': Adding as member to '$company'\n"
		im_biz_object_add_role $user_id $company_id [im_biz_object_role_full_member]
	    } else {
		ns_write "<li>'$first_name $last_name': Is already a member of '$company'\n"
	    }

	} else {

	    set company_name $company

	    set company_type 0
	    if {$profile_id == [im_profile_customers]} { set company_type_id [im_company_type_customer]}
	    if {$profile_id == [im_profile_freelancers]} { set company_type_id [im_company_type_freelance]}
	    set company_status_id [im_company_status_potential]

	    ns_write "<li>'$first_name $last_name': Unable to find the users company '$company'. Please <A href=\"/intranet/companies/new-company-from-user?[export_url_vars user_id company_type_id company_status_id company_name]\">click here to create it</a>.\n"

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
        ns_write "<li>'$first_name $last_name': Added to group '$profile_id'.\n"
    } else {
        ns_write "<li>'$first_name $last_name': Not adding the user to any group.\n"
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
#	    set excel_value [expr \$$excel_field]

	    set cmd "set excel_value \"\$$excel_field\""
	    eval $cmd

	} err_value]} {
	    if {"" != $err_value} { 
		ns_write "
		<li>Error evaluating '$excel_value' of Excel field '$excel_field' into column '$table_column':<br>
		<pre>command=$cmd\n$err_value</pre>
	        "
	    }
	}
	set excel_value [string trim $excel_value]

	if {"" != $excel_value} {

	    set res_list {}
	    set res_errors {"Error during transformation"}
	    
	    if {[catch {
#		set trans_result [eval $trans_function $excel_value]

		set cmd "set trans_result \[$trans_function \"$excel_value\"\]"
		eval $cmd

		set res_list [lindex $trans_result 0]
		set res_errors [lindex $trans_result 1]
	    } err_trans]} {
		if {"" != $err_value} { 
	            ns_write "
		    <li>Error transforming value '$excel_value' of Excel field '$excel_field' into column '$table_column':<br>
		    <pre>Command: $cmd\n$err_trans</pre>
	            "
		}
	    }

	    if {[llength $res_errors] > 0} {

		ns_write "
	<li>Error transforming value '$excel_value' of Excel field '$excel_field' into column '$table_column':<br>
	<pre>Error Summary: [join $res_errors "<br>\n"]</pre>"

	    } else {

		if {[catch {
		    # We found exactly one return value and no errors...
		    db_dml update_contact_dynfield "
	                update persons set 
				$table_column = :res_list
	                where person_id = :user_id
	            "
		} errmsg]} {
		    ns_write "<li>Error updating dynfield $table_column at user \#$user_id:<br><pre>$errmsg</pre>"
		}


	    }
        }
    }




}


# ------------------------------------------------------------
# Render Report Footer

ns_write [im_footer]
