# /packages/intranet-core/www/user/upload-users-2.tcl
#
# Copyright (C) 2013 ]project-open[
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
    @param
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    { upload_file "" }
    { locale_numeric "en_US" }
    { update_hourly_rates_skill_profile:optional }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

if { ![info exists security_token] } {
    set user_id [ad_maybe_redirect_for_registration]
} 

set temp_path [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "TempPath" -default "/tmp"]
set page_title ""
set context_bar ""

set str_length 40
set security_token [subst [string repeat {[format %c [expr {int(rand() * 26) + (int(rand() * 10) > 5 ? 97 : 65)}]]} $str_length]]

# -------------------------------------------------------------------
# Get the file
# -------------------------------------------------------------------

set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-users-2.tcl" -value $tmp_filename
set filesize [file size $tmp_filename]

if { $max_n_bytes && ($filesize > $max_n_bytes) } {
    # set util_commify_number_max_n_bytes [util_commify_number $max_n_bytes]
    ad_return_complaint 1 "[_ intranet-translation.lt_Your_file_is_larger_t_1]"
    ad_script_abort
}

# -------------------------------------------------------------------
# Copy the uploaded file into the template filestorage
# -------------------------------------------------------------------

ns_log NOTICE "intranet-core::users::upload-users-2: Now copying file: $temp_path/$security_token/$upload_file"

# Create tmp path
set temp_path_list [parameter::get -package_id [apm_package_id_from_key acs-subsite] -parameter "TmpDir" -default "/tmp"]
set temp_path [lindex $temp_path_list 0]

if { [catch {
            file mkdir "$temp_path/$security_token"
} err_msg] } {
            ad_return_complaint 1 "Could not create temp directory, please check if paramter 'TempPath' of package 'intranet-customer-portal' contains a valid path."
}


if { [catch {
    ns_cp $tmp_filename "$temp_path/$security_token/$upload_file"
} err_msg] } {
    ad_return_complaint 1 [lang::message::lookup "" intranet-core.ErrUploadingFile "There had been an error while uploading the file. Please contact your System Administrator: $err_msg"]

}

# -------------------------------------------------------------------
# Build column CSV from first line 
# -------------------------------------------------------------------

# Extract CSV contents

set csv_files_content [fileutil::cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set csv_files_len [llength $csv_files]

set separator [im_csv_guess_separator $csv_files]

# Split the header into its fields
set csv_header [string trim [lindex $csv_files 0]]
set csv_header_fields [im_csv_split $csv_header $separator]
# set csv_header_len [llength $csv_header_fields]

set select_options_import ""
set j 0


foreach option_text $csv_header_fields {
    if { "" == $option_text } {
	set option_text [lang::message::lookup "" intranet-core.NoTitleFound "--No title found--"]
    }
    append select_options_import "<option value='$j'>$option_text</option>"
    incr j
}

# -------------------------------------------------------------------
# Build options ]po[ User Attributes  
# -------------------------------------------------------------------

# TodDo: 
# Build this based on "User Default Attributes" & dynField 

set select_options_db "
	<option value='user_id'>Id</option>
	<option value='first_name'>First Name</option>
	<option value='last_names'>Last Name</option>
	<option value='email'>email</option>
	<option value='username'>Username</option>
	<option value='hourly_rate'>Hourly Rate</option>
"

set hidden_fields [export_form_vars security_token upload_file locale_numeric update_hourly_rates_skill_profile]

set update_hourly_rates_skill_profile_txt ""
if { [info exists update_hourly_rates_skill_profile] } {
    append update_hourly_rates_skill_profile_txt [lang::message::lookup "" intranet-core.HourlyCostsWillBeUpdated "Hourly Costs of Employees will be updated based on Skill Profiles"]
}

set notes_msg ""
if { "" != $update_hourly_rates_skill_profile_txt } {
    set notes_msg "
        [lang::message::lookup "" intranet-core.Notes "Notes"]<br>
        <ul>
	<li>$update_hourly_rates_skill_profile_txt</li>
        </ul>
    "
}
