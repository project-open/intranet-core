# /www/intranet/offices/new-2.tcl

ad_page_contract {
    Saves office info to db

    @param group_id The group_id of the office.
    @param group_name The group_name of the office.
    @param short_name The shor_name of the office.
    @param return_url The url to go to.
    @param dp.im_offices.facility_id
    @param dp.im_offices.public_p

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id new-2.tcl,v 3.4.2.9 2000/08/16 21:24:54 mbryzek Exp
} {
    group_id:optional,integer
    group_name:optional
    short_name:optional
    dp.im_offices.facility_id:optional
    dp.im_offices.public_p:optional
    dp.im_offices.group_id:optional
    dp_ug.user_groups.group_id:optional
    dp_ug.user_groups.group_type:optional
    dp_ug.user_groups.approved_p:optional
    dp_ug.user_groups.new_member_policy:optional
    dp_ug.user_groups.parent_group_id:optional
    dp_ug.user_groups.group_name:optional
    dp_ug.user_groups.short_name:optional

    dp_ug.user_groups.creation_user:optional
    dp_ug.user_groups.creation_ip_address:optional

    {return_url index}
}

set user_id [ad_maybe_redirect_for_registration]

if { ![exists_and_not_null group_id] }  {
    ad_return_error "We've lost the office's group id" "Please back up, hit reload, and try again."
    return
}
 
set required_vars [list \
	[list group_name "You must specify the office's name"] \
	[list short_name "You must specify the office's short name"] \
        [list dp.im_offices.facility_id "You must specify a facility where the office is located"]]

set errors [im_verify_form_variables $required_vars]

set exception_count 0
if { ![empty_string_p $errors] } {
    set exception_count 1
}


# Make sure short name is unique - this is enforced in user groups since short_name 
# must be unique for different UI stuff
if { ![empty_string_p $short_name] } {
    set exists_p [db_string intranet_offices_check_for_uniqueness \
	    "select decode(count(1),0,0,1) 
               from user_groups 
              where lower(trim(short_name))=lower(trim(:short_name))
                and group_id != :group_id" ]

    if { $exists_p } {
	incr exception_count
	append errors "  <li> The specified short name already exists for another user group. Please choose a new short name\n"
    }
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count $errors
    return
}

set form_setid [ns_getform]

# Create/update the user group frst since projects reference it
# Note: group_name, creation_user, creation_date are all set in new.tcl
ns_set put $form_setid "dp_ug.user_groups.group_id" $group_id
ns_set put $form_setid "dp_ug.user_groups.group_type" [ad_parameter IntranetGroupType intranet]
ns_set put $form_setid "dp_ug.user_groups.approved_p" "t"
ns_set put $form_setid "dp_ug.user_groups.new_member_policy" "closed"
ns_set put $form_setid "dp_ug.user_groups.parent_group_id" [util_memoize {im_group_id_from_parameter OfficeGroupShortName}]
ns_set put $form_setid "dp_ug.user_groups.group_name" $group_name
ns_set put $form_setid "dp_ug.user_groups.short_name" $short_name

# Put the group_id into the office information
ns_set put $form_setid "dp.im_offices.group_id" $group_id

db_transaction {

    # Update user_groups
    dp_process -form_index "_ug" -where_clause "group_id=:group_id"
    
    # Now update im_offices
    dp_process -where_clause "group_id=:group_id"
    
}

db_release_unused_handles

ad_returnredirect $return_url
