# /www/intranet/member-add-2.tcl
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
    Purpose: Confirms adding of person to group

    @param user_id_from_search user_id to add
    @param object_id group to which to add
    @param role_id role in which to add
    @param return_url Return URL
    @param also_add_to_group_id Additional groups to which to add

    @author mbryzek@arsdigita.com    
    @author frank.bergmann@project-open.com
} {
    user_id_from_search:integer
    { notify_asignee "0" }
    object_id:integer
    role_id:integer
    return_url
    { also_add_to_group_id:integer "" }
}

set user_id [ad_maybe_redirect_for_registration]

# expect commands such as: "im_project_permissions" ...
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1 "You have no rights to add members to this object."
    return
}

im_biz_object_add_role $user_id_from_search $object_id $role_id

if {0} {

    # Send out an email alert
    if {"" != $notify_asignee && ![string equal "0" $notify_asignee]} {
	set url "[ad_parameter SystemUrl]intranet/projects/view?object_id=$object_id"
	set sql "select group_name from user_groups where object_id=:object_id"
	set project_name [db_string project_name $sql]
	set subject "You have been added to project \"$project_name\""
	set message "Please click on the link above to access the project pages."
	
	im_send_alert $user_id_from_search "hourly" $url $subject $message
    }
}

ad_returnredirect $return_url

