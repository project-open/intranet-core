# /packages/intranet-core/www/member-add-3.tcl
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
    less stringent on permissions (i.e. any member of the group specified
    in limit_to_users_in_group_id can add themselves or anyone else)

    @param group_id 
    @param user_id_from_search 
    @param role
    @param existing_role
    @param new_role
    @param return_url 
    @param also_add_to_group_id 
    @param limit_to_users_in_group_id 
    @param start_date

    @author mbryzek@arsdigita.com
} {
    group_id:naturalnum,notnull
    { role "" }
    { existing_role "" }
    { new_role "" }
    { user_id_from_search:naturalnum "" }
    { return_url "" }
    { also_add_to_group_id:naturalnum "" }
    { limit_to_users_in_group_id:naturalnum "" }
    start_date:array,date,optional
} -validate {
    start_date_is_needed {
	if { $group_id == [im_employee_group_id] && ![info exists start_date(date)] } {
	    ad_complain
	} elseif { $group_id == [im_employee_group_id] && [empty_string_p $start_date(date)] } {
	    ad_complain
	}
    }
} -errors {
    start_date_is_needed { You must enter the start date of the employee }
}
    

if { [empty_string_p $user_id_from_search] } {
    set user_id_from_search [ad_maybe_redirect_for_registration]
}

if { ![exists_and_not_null role] } {
    if { [exists_and_not_null new_role] } {
	set role $new_role
    } elseif { [exists_and_not_null existing_role] } {
	set role $existing_role
    } else {
	ad_return_error "No role specified" "We couldn't figure out what role this new member is supposed to have; either you didn't choose one or there is a bug in our software."
	return
    }
}

set user_id [ad_maybe_redirect_for_registration]

if { ![db_0or1row get_group_type_policy \
	"select group_type, new_member_policy from user_groups where group_id = :group_id"] } {
    ad_return_error "Couldn't find group" "We couldn't find the group $group_id. Must be a programming error."
    return
}

if { ![ad_administrator_p $user_id] } {

    # Is the person an authorized intranet user?
    if { ![im_user_is_authorized_p $user_id] } {
	if { ![info exists limit_to_users_in_group_id] || ![im_can_user_administer_group $limit_to_users_in_group_id $user_id] } {
	
	    if { $new_member_policy != "open" } {
		ad_return_complaint 1 "<li>The group you are attempting to add a member to 
		does not have an open new member policy."
		return
	    }
	}
    }
}

set mapping_user [ad_get_user_id]

set mapping_ip_address [ns_conn peeraddr]

if { [info exists start_date(date)] } {
    set the_date $start_date(date)
} 

db_transaction {
    db_dml user_group_delete \
	    "delete from user_group_map 
             where group_id = :group_id and user_id = :user_id_from_search"

    db_dml user_group_insert \
	    "insert into user_group_map 
                         (group_id, user_id, role, mapping_user, mapping_ip_address) 
                  select :group_id, :user_id_from_search, :role, 
                         :mapping_user, :mapping_ip_address 
                  from dual 
                  where ad_user_has_role_p (:user_id_from_search, :group_id, :role) <> 't'"

    # Extra fields
    db_foreach fields \
	    "select field_name from all_member_fields_for_group where group_id = :group_id" {
	
	if { [exists_and_not_null $field_name] } {
	    set field_value [set $field_name]

	    db_dml extra_field_insert \
		    "insert into user_group_member_field_map
	                    (group_id, user_id, field_name, field_value)
	    values (:group_id, :user_id_from_search, :field_name, :field_value)" 
        }
    }    
} on_error {
    ad_return_error "Database Error" "
    Error while trying to insert user into a user group.
    Database error message was:	<blockquote><pre>$errmsg</pre></blockquote>"
    return
}


# Send out an email alert
set notify_asignee 1
if {$notify_asignee} {
    set url "[ad_parameter SystemUrl]intranet/projects/view?group_id=$group_id"
    set sql "select group_name from user_groups where group_id=:group_id"
    set project_name [db_string project_name $sql]
    set subject "You have been added to project \"$project_name\""
    set message "Please click on the link above to access the project pages."

    im_send_alert $user_id_from_search "hourly" $url $subject $message
}



db_release_unused_handles

if { [exists_and_not_null also_add_to_group_id] } {
    # Have to add the user to one more group - do it!
    ad_returnredirect "member-add-3.tcl?group_id=$also_add_to_group_id&[export_ns_set_vars url [list group_id also_add_to_group_id user_id_from_search]]"
} elseif { [exists_and_not_null return_url] } {
    if {[string match *\[?\]* $return_url] == 1} {
	if {[string match *[ad_urlencode user_id_from_search]* $return_url] == 1} {
	    ad_returnredirect $return_url
	} else {	
	    ad_returnredirect $return_url&[export_url_vars user_id_from_search]
	}
    } else {
	ad_returnredirect $return_url?[export_url_vars user_id_from_search]
    }
} else {
    ad_returnredirect "index"
}

