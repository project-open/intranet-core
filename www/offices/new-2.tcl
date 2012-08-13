# /packages/intranet-core/www/offices/new-2.tcl
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
    Writes all the office information to the db. 

    @param office_id The group this office belongs to 
    @param start Date this office starts.
    @param return_url The Return URL
    @param creation_ip_address IP Address of the creating user (if we're creating this group)
    @param creation_user User ID of the creating user (if we're creating this group)
    @param group_name Office's name
    @param office_path Group short name for things like email aliases
    @param referral_source How did this office find us
    @param office_status_id What's the office's status
    @param office_type_id The type of the office
    @param annual_revenue.money How much they make
    @param note General notes about the office

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)

} {
    office_id:integer,notnull
    { office_name "" }
    { office_path "" }
    { office_status_id:integer "" }
    { office_type_id:integer "" }
    { company_id:integer "" }
    { return_url "" }
    { note "" }
    { phone "" }
    { fax "" }
    { address_line1 "" }
    { address_line2 "" }
    { address_city "" }
    { address_postal_code "" }
    { address_country_code "" }
    { ignore_max_hours_per_day_p "" }
}

# -----------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------

if {"" == $office_name} {
    set office_name "[_ intranet-core.lt_office_name_Main_Offi]"
}

if {"" == $ignore_max_hours_per_day_p} {
    set ignore_max_hours_per_day_p "f"
} 


# -----------------------------------------------------------------
# Check for Errors in Input Variables
# -----------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
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

# -----------------------------------------------------------------
# Create a new Office if it didn't exist yet
# -----------------------------------------------------------------

# Double-Click protection: the office Id was generated at the new.tcl page
set office_count [db_string office_count "select count(*) from im_offices where office_id=:office_id"]
if {0 == $office_count} {

    db_transaction {
	# create a new Office:
	set office_id [office::new \
		-office_name	$office_name \
		-office_path	$office_name \
		-office_status_id $office_status_id \
		-office_type_id $office_type_id]

# fraber 060307: Dont make the user a member of the office-
# its not used very frequently and freelancers who can see
# employees may get the list of customers from the offices...
#	
#	 add users to the office as office_admin
#        set role_id [im_biz_object_role_office_admin]
#        im_biz_object_add_role $user_id $office_id $role_id

    }
}

# -----------------------------------------------------------------
# Update the Office
# -----------------------------------------------------------------

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
	note = :note,
	ignore_max_hours_per_day_p = :ignore_max_hours_per_day_p
where
	office_id = :office_id
"
    db_dml update_offices $update_sql

    im_audit -object_type "im_office" -object_id $office_id -action after_update


db_release_unused_handles

ad_returnredirect $return_url
