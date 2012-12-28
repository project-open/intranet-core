# /packages/intranet-core/www/offices/new.tcl
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

ad_page_contract {
    Lets users add/modify information about our offices.

    @param office_id if specified, we edit the office with this office_id
    @param return_url Return URL

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
    
} {
    { office_id:integer 0 }
    { office_name "" }
    { office_path "" }
    { office_status_id:integer "" }
    { office_type_id:integer "" }
    { company_id:integer "" }
    { note "" }
    { phone "" }
    { fax "" }
    { address_line1 "" }
    { address_line2 "" }
    { address_city "" }
    { address_postal_code "" }
    { address_country_code "" }
    { return_url "" }
}

# -- ------------------------------
# -- Defaults and Permissions 
# -- ------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set page_title [_ intranet-core.Office]
set context_bar [im_context_bar [list index "[_ intranet-core.Offices]"] [list "view?[export_url_vars office_id]" "[_ intranet-core.One_office]"] $page_title]

# -- ------------------------------------------------
# -- General Settings
# -- ------------------------------------------------    

set creation_ip_address [ns_conn peeraddr]
set creation_user $user_id

# -- ------------------------------------------------
# -- Setting labels 
# -- ------------------------------------------------
    
set department_label "[_ intranet-hr.Department]"
set office_name_label "[_ intranet-core.Office_Name]"
set office_path_label  "[_ intranet-core.lt_Office_Directory_Path]"
set company_label  "[_ intranet-core.Company]"
set office_status_label "[_ intranet-core.Office_Status]"
set office_type_label "[_ intranet-core.Office_Type]"
set phone_label "[_ intranet-core.Phone]"
set fax_label "[_ intranet-core.Fax]"
set address_line1_label "[_ intranet-core.Address_1]"
set address_line2_label "[_ intranet-core.Address_2]"
set address_postal_code_label "[_ intranet-core.ZIP]"
set address_city_label "[_ intranet-core.City]"
set address_country_code_label "[_ intranet-core.Country]"
set note_label "[_ intranet-core.Notes]"

# -- ------------------------------------------------
# -- Build the form
# -- ------------------------------------------------

set country_options [im_country_options]
set company_options [im_company_options -include_empty_p 1 -status "Active or Potential" -type ""]
set form_id "office"

template::form::create $form_id
template::form::section $form_id ""
template::element::create $form_id office_name -label $office_name_label -html {size 30} -datatype text -maxlength 1000
template::element::create $form_id office_path -label $office_path_label -html {size 30} -datatype text -maxlength 100
template::element::create $form_id company_id -datatype integer -optional -label $company_label -widget "select"  -options $company_options

template::element::create $form_id office_status_id \
    -optional \
    -datatype integer \
    -label $office_status_label \
    -widget "im_category_tree" \
    -custom {category_type "Intranet Office Status"}

template::element::create $form_id office_type_id -optional \
    -label $office_type_label \
    -widget "im_category_tree" \
    -custom {category_type "Intranet Office Type"}

template::element::create $form_id phone \
    -optional \
    -label $phone_label \
    -html {size 15} \
    -datatype text \
    -maxlength 50 

template::element::create $form_id fax -optional -label $fax_label -html {size 15} -datatype text -maxlength 50
template::element::create $form_id address_line1 -optional -label $address_line1_label -html {size 30} -datatype text -maxlength 80
template::element::create $form_id address_line2 -optional -label $address_line2_label -html {size 30} -datatype text -maxlength 80
template::element::create $form_id address_postal_code -optional -label $address_postal_code_label -html {size 5} -datatype text -maxlength 80
template::element::create $form_id address_city -optional -label $address_city_label -html {size 30} -datatype text -maxlength 80
template::element::create $form_id address_country_code -datatype text -optional -label $address_country_code_label -widget "select"  -options $country_options
template::element::create $form_id note -optional -datatype text -widget textarea -label $note_label -html {rows 6 cols 30} -maxlength 4000

# Hidden fields
template::element::create $form_id return_url -optional -widget "hidden" -datatype text
template::element::create $form_id office_id -optional -widget "hidden"
template::element::create $form_id creation_ip_address -datatype text -optional -widget "hidden" 
template::element::create $form_id creation_user -optional -widget "hidden"
# template::element::create $form_id main_office_id -optional -widget "hidden"

set field_cnt [im_dynfield::append_attributes_to_form \
		       -object_subtype_id "" \
		       -object_type "im_office" \
		       -form_id $form_id \
		       -object_id $office_id \
]

# -- ------------------------------------------------
# -- Form handling -> Submission  
# -- ------------------------------------------------

if {[form is_submission $form_id] && [template::form::is_valid $form_id] } {

    im_dynfield::attribute_validate \
            -object_type "im_office" \
            -object_id $office_id \
            -form_id $form_id

    if {"" == $office_name} {
	set office_name "[_ intranet-core.lt_office_name_Main_Offi]"
    }

    # Check for Errors in Input Variables
    set form_setid [ns_getform]

    set required_vars [list \
			   [list "office_name" "You must specify the office's name"] \
			   [list "office_path" "You must specify a short name"]]
    set errors [im_verify_form_variables $required_vars]
    set exception_count 0

    if { ![empty_string_p $errors] } {
	incr exception_count
    }

    if { [string length ${note}] > 4000 } {
	incr exception_count
	append errors "  <li>[_ intranet-core.lt_The_note_you_entered_]"
    }

    # Periods don't work in bind variables...
    set office_path ${office_path}

    # Make sure office name is unique
    set exists_p [db_string group_exists_p "
	select count(*)
	from im_offices
	where office_id != :office_id and
        ( lower(trim(office_path)) = lower(trim(:office_path))
          or lower(trim(office_name)) = lower(trim(:office_name))
        )
    "]

    if { $exists_p } {
	incr exception_count
	append errors "  <li>[_ intranet-core.lt_An_office_with_the_sa]"
    }

    if { ![empty_string_p $errors] } {
	ad_return_complaint $exception_count "<ul>$errors</ul>"
	return
    }


    # Create a new Office if it didn't exist yet

    # Double-Click protection: the office Id was generated at the new.tcl page
    set office_count [db_string office_count "select count(*) from im_offices where office_id=:office_id"]
    if {0 == $office_count} {
	db_transaction {
	    # create a new Office:
	    set office_id [office::new \
	       -office_name	$office_name \
	       -office_path	$office_path \
	       -office_status_id $office_status_id \
	       -office_type_id $office_type_id]
	}
    }

    # Update the Office
    set update_sql "
    	update im_offices set
	       office_name = :office_name,
	       office_path = :office_path,
	       office_status_id = :office_status_id,
	       office_type_id = :office_type_id,
	       company_id = :company_id,
	       phone = :phone,
	       fax = :fax,
	       address_line1 = :address_line1,
	       address_line2 = :address_line2,
	       address_city = :address_city,
	       address_postal_code = :address_postal_code,
	       address_country_code = :address_country_code,
	       note = :note
	where
	       office_id = :office_id
    "
    db_dml update_offices $update_sql

    im_dynfield::attribute_store \
            -object_type "im_office" \
            -object_id $office_id \
            -form_id $form_id

    im_audit -object_type "im_office" -object_id $office_id -action after_update

    db_release_unused_handles

    ad_returnredirect $return_url

}


# -- ------------------------------------------------
# -- Form handling -> Request 
# -- ------------------------------------------------

if { [form is_request $form_id] } {

    if { "0" == $office_id } {

	# Check privilege for "Adding offices"
	if { [form is_request $form_id] && "0" == $office_id && ![im_permission $user_id "add_offices"] && !$user_admin_p } {
	    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "<li>[_ intranet-core.lt_You_dont_have_suffici_1]"
	}

	set page_title [_ intranet-core.Add_New_Office]
	set button_text [lang::message::lookup "" intranet-core.CreateOffice "Create Office"]

	set office_id [im_new_object_id]
	set office_name ""
	set office_path "" 
	set company_id ""
	set office_status_id 160; # Active
	set office_type_id 170; # Main Office
	set phone "" 
	set fax "" 
	set address_line1 "" 
	set address_line2 ""
	set address_postal_code "" 
	set address_city "" 
	set address_country_code "" 
	set note "" 
	# set main_office_id ""

    } else {

	set page_title [lang::message::lookup "" intranet-core.Edit_office "Edit Office"]
	set button_text "[_ intranet-core.Save_Changes]"

	if {![db_0or1row office_get_info "
	    select	o.*
	    from	im_offices o
	    where	o.office_id=:office_id
	" 
	]} {
	    ad_return_error "[_ intranet-core.lt_Office_office_id_does]" "[_ intranet-core.lt_Please_back_up_and_tr]"
	    return
	}
    }

    template::element::set_value $form_id office_name $office_name 
    template::element::set_value $form_id office_path $office_path 
    template::element::set_value $form_id company_id $company_id 
    template::element::set_value $form_id office_status_id $office_status_id 
    template::element::set_value $form_id office_type_id $office_type_id 
    template::element::set_value $form_id phone $phone 
    template::element::set_value $form_id fax $fax 
    template::element::set_value $form_id address_line1 $address_line1 
    template::element::set_value $form_id address_line2 $address_line2 
    template::element::set_value $form_id address_postal_code $address_postal_code 
    template::element::set_value $form_id address_city $address_city 
    template::element::set_value $form_id address_country_code $address_country_code 
    template::element::set_value $form_id note $note 

    # Hidden fields
    template::element::set_value $form_id return_url $return_url 
    template::element::set_value $form_id office_id $office_id 
    template::element::set_value $form_id creation_ip_address $creation_ip_address 
    template::element::set_value $form_id creation_user $creation_user 
    # template::element::set_value $form_id main_office_id $main_office_id 
    
    # Button txt
    template::form::set_properties $form_id edit_buttons "[list [list "$button_text" ok]]"

}

