# /www/intranet/facilities/new-2.tcl
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
    Saves office info to db

    @author Mark C (markc@arsdigita.com)
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id new-2.tcl,v 1.3.2.17 2000/09/13 18:21:40 mbryzek Exp
} {
    office_id:naturalnum,notnull
    office_name:optional,trim
    return_url:optional
    dp.im_offices.creation_ip_address:optional
    dp.im_offices.creation_user:naturalnum,optional
    { dp.im_offices.phone.phone "" }
    { dp.im_offices.fax.phone "" }
    { dp.im_offices.address_line1 "" }
    { dp.im_offices.address_line2 "" }
    { dp.im_offices.address_city "" }
    { dp.im_offices.address_state "" }
    { dp.im_offices.address_country_code "" }
    { dp.im_offices.address_postal_code "" }
    { dp.im_offices.landlord:html "" }
    { dp.im_offices.security:html "" }
    { dp.im_offices.note:html "" }
    { dp.im_offices.office_id "" }
    { dp.im_offices.office_name "" }
    { province ""}
    
}

set user_id [ad_maybe_redirect_for_registration]

set required_vars [list \
	[list office_name "You must specify the office's name"] ]

set errors [im_verify_form_variables $required_vars]

set exception_count 0
if { ![empty_string_p $errors] } {
    set exception_count 1
}

# Make sure name is unique - this is enforced in user groups since short_name 
# must be unique for different UI stuff


set exists_p [db_string unique_name_p \
	"select decode(count(1),0,0,1) 
          from im_offices 
          where lower(trim(office_name)) = lower(trim(:office_name))
          and office_id != :office_id"]

if { $exists_p } {
   incr exception_count
   append errors "  <li> The specified name already exists for another office. Please choose a new name.\n"
}

# validate zip code
#if [catch { [validate_zip_code zip $test_zip "US"]} errmsg] {
#    incr exception_count
#    append errors "<li> $errmsg" 
#}
if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count $errors
    return
}

set form_setid [ns_getform]
ns_set put $form_setid "dp.im_offices.office_id" $office_id
ns_set put $form_setid "dp.im_offices.office_name" $office_name

if { [string tolower [value_if_exists dp.im_offices.address_country_code]] != "us" } {
    ns_set delkey $form_setid "dp.im_offices.address_state"
    ns_set put $form_setid "dp.im_offices.address_state" $province
}

dp_process -where_clause "office_id=:office_id"

db_release_unused_handles
if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index
}





