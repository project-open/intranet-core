# /www/intranet/member-add-2.tcl

ad_page_contract {
    Purpose: Confirms adding of person to group

    @param user_id_from_search user_id to add
    @param group_id group to which to add
    @param role role in which to add
    @param return_url Return URL
    @param also_add_to_group_id Additional groups to which to add

    @author mbryzek@arsdigita.com
    @creation-date 4/16/2000

    @cvs-id member-add-2.tcl,v 3.5.2.8 2000/10/27 00:03:00 tony Exp
} {
    user_id_from_search:integer
    { notify_asignee "0" }
    group_id:integer
    role
    return_url
    { also_add_to_group_id:integer "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_group_member_p [ad_user_group_member $group_id $user_id]
set user_is_group_admin_p [im_can_user_administer_group $group_id $user_id]
set user_admin_p [expr $user_is_admin_p + $user_is_group_admin_p]

ns_log Notice "member-add-2: notify_asignee=$notify_asignee"

if {!$user_admin_p} {
    set err_msg "You are not an administator of this group.<br>\
    The system administator will be notified."

    ad_return_error "Insufficient Permissions" $err_msg
}

db_transaction {

    set already_member [db_string select_already_member "select count(*) from group_distinct_member_map where group_id=:group_id and member_id=:user_id_from_search"]

    if {$already_member} {
	group::remove_member \
	    -group_id $group_id \
	    -user_id $user_id_from_search
    }

    group::add_member \
	-group_id $group_id \
	-user_id $user_id_from_search \
	-rel_type $role
}


if {0} {

    # Send out an email alert
    if {"" != $notify_asignee && ![string equal "0" $notify_asignee]} {
	set url "[ad_parameter SystemUrl]intranet/projects/view?group_id=$group_id"
	set sql "select group_name from user_groups where group_id=:group_id"
	set project_name [db_string project_name $sql]
	set subject "You have been added to project \"$project_name\""
	set message "Please click on the link above to access the project pages."
	
	im_send_alert $user_id_from_search "hourly" $url $subject $message
    }
}

ad_returnredirect $return_url

