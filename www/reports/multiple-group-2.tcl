# /www/intranet/reports/multiple-group-2.tcl

ad_page_contract {
    this page is the target of the form on multiple-group.tcl
    it will loop through all the variables in the form.
    if the variable is set to "" then it will do no update
    otherwise it will select a list of groups that that user belongs to, and set role to secondary
    the selected group will remain unchanged.

    @param user
    @param group_type

    @author unknown
   
    @cvs-id multiple-group-2.tcl,v 1.2.2.7 2000/08/16 21:25:03 mbryzek Exp
} {
    user:array,optional
    group_type:notnull
}

ad_maybe_redirect_for_registration

if { [string compare $group_type "team"] == 0 } {
    set parent_group_id [im_team_group_id]
} else {
    set parent_group_id [im_office_group_id]
}

foreach user_id_to_update [array names user] {
    set group_id $user($user_id_to_update)
    db_dml update_misssing_group \
          {update user_group_map set role = 'secondary' 
	   where user_id = :user_id_to_update 
                 and group_id in (select ug.group_id
	                          from user_groups ug, user_group_map ugm 
    	                          where ugm.user_id = :user_id_to_update
	                                and ug.group_id=ugm.group_id 
	                                and ug.group_id!= :group_id
	                                and ug.parent_group_id = :parent_group_id
	                                and lower(ugm.role) != 'secondary')} 
}

db_release_unused_handles
ad_returnredirect "multiple-group?[export_url_vars group_type]"

