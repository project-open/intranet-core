# /packages/intranet-core/www/companies/new-2.tcl
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
    Writes all the company information to the db. 

    @param company_id The group this company belongs to 
    @param start Date this company starts.
    @param return_url The Return URL
    @param creation_ip_address IP Address of the creating user (if we're creating this group)
    @param creation_user User ID of the creating user (if we're creating this group)
    @param group_name Company's name
    @param company_path Group short name for things like email aliases
    @param referral_source How did this company find us
    @param company_status_id What's the company's status
    @param company_type_id The type of the company
    @param annual_revenue.money How much they make
    @param note General notes about the company

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)

} {
    company_id:integer,notnull
    { company_name "" }
    { company_path "" }
    company_status_id:integer,notnull
    company_type_id:integer,notnull
    { main_office_id:integer "" }
    { return_url "" }
    { group_type "" }
    { approved_p "" }
    { new_member_policy "" }
    { parent_group_id "" }
    { referral_source "" }
    { annual_revenue_id "" }
    { vat_number "" }
    { note "" }
    { contract_value "" }
    { site_concept "" }
    { manager_id "" }
    { billable_p "" }
    { start_date "" }
    { phone "" }
    { fax "" }
    { address_line1 "" }
    { address_line2 "" }
    { address_city "" }
    { address_state "" }
    { address_postal_code "" }
    { address_country_code "" }
    { start:array,date "" }
    { old_company_status_id "" }
    { status_modification_date.expr "" }
    { also_add_users "" }
}

# -----------------------------------------------------------------
# Check for Errors in Input Variables
# -----------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set form_setid [ns_getform]

set required_vars [list \
    [list "company_name" "You must specify the company's name"] \
    [list "company_path" "You must specify a short name"]]
set errors [im_verify_form_variables $required_vars]
set exception_count 0

if { ![empty_string_p $errors] } {
    incr exception_count
}

if { [string length ${note}] > 4000 } {
    incr exception_count
    append errors "  <li>[_ intranet-core.lt_The_note_you_entered_]"
}




# -----------------------------------------------------------------
# To-Lower the company path and check for alphanum characters
#
set normalize_company_path_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NormalizeCompanyPathP" -default 1]

if {$normalize_company_path_p} {
    set company_path [string tolower [string trim $company_path]]
    
    if {![regexp {^[a-z0-9_]+$} $company_path match]} {
	incr exception_count
	append errors "  <li>[lang::message::lookup "" intranet-core.Non_alphanum_chars_in_path "The specified path contains invalid characters. Allowed are only aphanumeric characters from a-z, 0-9 and '_'."]: '$company_path'"
    }
}


# Make sure company name is unique
set exists_p [db_string group_exists_p "
	select count(*)
	from im_companies
	where lower(trim(company_path))=lower(trim(:company_path))
            and company_id != :company_id
"]

if { $exists_p } {
    incr exception_count
    append errors "  <li>[_ intranet-core._The]"
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count "<ul>$errors</ul>"
    return
}


# ------------------------------------------------------------------
# Permissions
# ------------------------------------------------------------------

# Check if we are creating a new company or editing an existing one:
set company_exists_p 0
if {[info exists company_id]} {
    set company_exists_p [db_string company_exists "
        select count(*)
        from im_companies
        where company_id = :company_id
    "]
}

if {$company_exists_p} {

    # Check company permissions for this user
    im_company_permissions $user_id $company_id view read write admin
    if {!$write} {
        ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
            <li>[_ intranet-core.lt_You_dont_have_suffici]"
        return
    }

} else {

    if {![im_permission $user_id add_companies]} {
        ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
            <li>[_ intranet-core.lt_You_dont_have_suffici]"
        return
    }

}



# -----------------------------------------------------------------
# Create a new Company if it didn't exist yet
# -----------------------------------------------------------------

if {![exists_and_not_null office_name]} {
    set office_name "$company_name [_ intranet-core.Main_Office]"
}
if {![exists_and_not_null office_path]} {
    set office_path "$company_path"
}

# Double-Click protection: the company Id was generated at the new.tcl page
if {0 == $company_exists_p} {

    # Disabled db_transaction here. This causes
    # a strange erroron V4.0, at least on Windows...

    # First create a new main_office:
    set main_office_id [office::new \
		-office_name		$office_name \
		-company_id     	$company_id \
		-office_type_id 	[im_office_type_main] \
		-office_status_id	[im_office_status_active] \
		-office_path		$office_path]

    # add users to the office as 
    set role_id [im_biz_object_role_office_admin]
    im_biz_object_add_role $user_id $main_office_id $role_id
    
    ns_log Notice "/companies/new-2: main_office_id=$main_office_id"
    
    # Now create the company with the new main_office:
    set company_id [company::new \
		-company_id		$company_id \
		-company_name		$company_name \
		-company_path		$company_path \
		-main_office_id		$main_office_id \
		-company_type_id	$company_type_id \
		-company_status_id	$company_status_id \
    ]
	
    # add users to the company as key account
    set role_id [im_biz_object_role_key_account]
    im_biz_object_add_role $user_id $company_id $role_id

}


# -----------------------------------------------------------------
# Update the Office
# -----------------------------------------------------------------

# fraber 071120: Dont update office name, it can be changed
#       office_name = :office_name,

db_dml update_offices "
update im_offices set
	phone =			:phone,
	fax =			:fax,
	address_line1 = 	:address_line1,
	address_line2 = 	:address_line2,
	address_city =		:address_city,
	address_state = 	:address_state,
	address_postal_code =	:address_postal_code,
	address_country_code =	:address_country_code
where
	office_id = :main_office_id
"


# -----------------------------------------------------------------
# Update the Company
# -----------------------------------------------------------------

db_dml update_company "
update im_companies set
	company_name		= :company_name,
	company_path		= :company_path,
	vat_number		= :vat_number,
	company_status_id	= :company_status_id,
	old_company_status_id	= :old_company_status_id,
	company_type_id		= :company_type_id,
	referral_source		= :referral_source,
	start_date		= :start_date,
	annual_revenue_id	= :annual_revenue_id,
	contract_value		= :contract_value,
	site_concept		= :site_concept,
	manager_id		= :manager_id,
	billable_p		= :billable_p,
	note			= :note
where
	company_id = :company_id
"


# Audit the action
if {0 == $company_exists_p} {
    im_audit -object_type "im_office" -object_id $main_office_id -type_id [im_office_type_main] -status_id [im_office_status_active] -action after_create
    im_audit -object_type "im_company" -object_id $company_id -type_id $company_type_id -status_id $company_status_id -action after_create
} else {
    im_audit -object_type "im_office" -object_id $main_office_id -type_id [im_office_type_main] -status_id [im_office_status_active] -action after_update
    im_audit -object_type "im_company" -object_id $company_id -type_id $company_type_id -status_id $company_status_id -action after_update
}

# -----------------------------------------------------------------
# Make sure the creator and the manager become Key Accounts
# -----------------------------------------------------------------

set role_id [im_company_role_key_account]

im_biz_object_add_role $user_id $company_id $role_id
if {"" != $manager_id } {
    im_biz_object_add_role $manager_id $company_id $role_id
}


# Add additional users to the company
array set also_add_hash $also_add_users
foreach uid [array names also_add_hash] {
    set role_id $also_add_hash($uid)
    ns_log Notice "/intranet/companies/new-2: add user $uid to company $company_id with role $role_id"
    im_biz_object_add_role $uid $company_id $role_id
}


# -----------------------------------------------------------------
# Store dynamic fields
# -----------------------------------------------------------------

if {[im_table_exists im_dynfield_attributes]} {

    set form_id "company"
    set object_type "im_company"

    template::form::create $form_id

    ns_log Notice "companies/new-2: before append_attributes_to_form"
    im_dynfield::append_attributes_to_form \
        -object_type $object_type \
        -form_id $form_id \
        -object_id $company_id

    ns_log Notice "companies/new-2: before attribute_store"
    im_dynfield::attribute_store \
	-object_type $object_type \
	-object_id $company_id \
	-form_id $form_id
    ns_log Notice "companies/new-2: after attribute_store"

}


# ------------------------------------------------------
# Finish
# ------------------------------------------------------

db_release_unused_handles


# Return to the new company page after creating
if {"" == $return_url} {
    set return_url [export_vars -base "/intranet/companies/view?" {company_id}]
}

ad_returnredirect $return_url
