# /www/intranet/partners/new-2.tcl

ad_page_contract {
    Stores partner info in db

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id new-2.tcl,v 3.6.2.10 2000/08/16 21:24:56 mbryzek Exp
} {
    { return_url "" }
    { group_id "" }
    { dp_ug.user_groups.creation_ip_address "" }
    { dp_ug.user_groups.creation_user "" }
    { dp_ug.user_groups.group_name "" }
    { dp_ug.user_groups.short_name "" }
    { dp.im_partners.referral_source "" }
    { dp.im_partners.partner_type_id "" }
    { dp.im_partners.partner_status_id "" }
    { dp.im_partners.annual_revenue_id "" }
    { dp.im_partners.url "" }
    { dp.im_partners.note "" }
    dp_ug.user_groups.group_id:integer,optional
    dp_ug.user_groups.group_type:optional
    dp_ug.user_groups.approved_p:optional
    dp_ug.user_groups.new_member_policy:optional
    dp_ug.user_groups.parent_group_id:integer,optional
    dp_ug.user_groups.modification_date.expr:optional
    dp_ug.user_groups.modifying_user:integer,optional
    dp.im_partners.group_id:integer,optional
}

set user_id [ad_maybe_redirect_for_registration]

set required_vars [list \
	[list "dp_ug.user_groups.group_name" "You must specify the partner's name"] \
	[list "dp_ug.user_groups.short_name" "You must specify the partner's short name"]]

set errors [im_verify_form_variables $required_vars]

set exception_count 0
if { ![empty_string_p $errors] } {
    incr exception_count
}


# Make sure partner name is unique
set short_name ${dp_ug.user_groups.short_name}
set exists_p [db_string check_exists \
	"select decode(count(ug.group_id),0,0,1)
           from user_groups ug
          where ug.short_name = :short_name
            and ug.group_id <> :group_id"]

if { $exists_p > 0 } {
    incr exception_count
    append errors "  <li> The specified short name, <b>$short_name</b>, already exists.\n"
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
ns_set put $form_setid "dp_ug.user_groups.parent_group_id" [im_partner_group_id]


# Log the modification date
ns_set put $form_setid "dp_ug.user_groups.modification_date.expr" sysdate
ns_set put $form_setid "dp_ug.user_groups.modifying_user" $user_id


# Put the group_id into im_partners. Also used for where clause
ns_set put $form_setid "dp.im_partners.group_id" $group_id

db_transaction {

    # Update user_groups
    dp_process -form_index "_ug" -where_clause "group_id=:group_id"

    # Now update im_projects
    dp_process -where_clause "group_id=:group_id"
    
}

db_release_unused_handles

if { ![exists_and_not_null return_url] } {
    set return_url [im_url_stub]/partners/view?[export_url_vars group_id]
}

if { [exists_and_not_null dp_ug.user_groups.creation_user] } {
    # add the creating current user to the group
    ad_returnredirect "[im_url_stub]/member-add-3?[export_url_vars group_id return_url]&user_id_from_search=$user_id&role=administrator"
} else {
    ad_returnredirect $return_url
}
