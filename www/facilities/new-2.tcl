# /www/intranet/facilities/new-2.tcl

ad_page_contract {
    Saves facility info to db

    @author Mark C (markc@arsdigita.com)
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id new-2.tcl,v 1.3.2.17 2000/09/13 18:21:40 mbryzek Exp
} {
    facility_id:naturalnum,notnull
    facility_name:optional,trim
    return_url:optional
    dp.im_facilities.creation_ip_address:optional
    dp.im_facilities.creation_user:naturalnum,optional
    { dp.im_facilities.phone.phone "" }
    { dp.im_facilities.fax.phone "" }
    { dp.im_facilities.address_line1 "" }
    { dp.im_facilities.address_line2 "" }
    { dp.im_facilities.address_city "" }
    { dp.im_facilities.address_state "" }
    { dp.im_facilities.address_country_code "" }
    { dp.im_facilities.address_postal_code "" }
    { dp.im_facilities.landlord:html "" }
    { dp.im_facilities.security:html "" }
    { dp.im_facilities.note:html "" }
    { dp.im_facilities.facility_id "" }
    { dp.im_facilities.facility_name "" }
    { province ""}
    
}

set user_id [ad_maybe_redirect_for_registration]

set required_vars [list \
	[list facility_name "You must specify the facility's name"] ]

set errors [im_verify_form_variables $required_vars]

set exception_count 0
if { ![empty_string_p $errors] } {
    set exception_count 1
}

# Make sure name is unique - this is enforced in user groups since short_name 
# must be unique for different UI stuff


set exists_p [db_string unique_name_p \
	"select decode(count(1),0,0,1) 
          from im_facilities 
          where lower(trim(facility_name)) = lower(trim(:facility_name))
          and facility_id != :facility_id"]

if { $exists_p } {
   incr exception_count
   append errors "  <li> The specified name already exists for another facility. Please choose a new name.\n"
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
ns_set put $form_setid "dp.im_facilities.facility_id" $facility_id
ns_set put $form_setid "dp.im_facilities.facility_name" $facility_name

if { [string tolower [value_if_exists dp.im_facilities.address_country_code]] != "us" } {
    ns_set delkey $form_setid "dp.im_facilities.address_state"
    ns_set put $form_setid "dp.im_facilities.address_state" $province
}

dp_process -where_clause "facility_id=:facility_id"

db_release_unused_handles
if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index
}





