# /packages/intranet-core/www/member-add-2.tcl
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
    user_id_from_search:integer,multiple
    { notify_asignee 0 }
    object_id:integer
    role_id:integer
    return_url
    { also_add_to_group_id:integer "" }
    { subject_l10n_key "intranet-core.lt_role_name_of_object_ns"}
    { body_l10n_key "intranet-core.lt_Dear_first_names_froms" }
}
       

set user_id [auth::require_login]
callback im_before_member_add -user_id $user_id_from_search -object_id $object_id 

# expect commands such as: "im_project_permissions" ...
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1 "You have no rights to add members to this object."
    return
}

# No role specified? => Return
if {"" eq $role_id} { ad_returnredirect $return_url }
if {0 eq $object_id } { ad_returnredirect $return_url }


set touched_p 0
foreach uid $user_id_from_search {
    im_biz_object_add_role $uid $object_id $role_id
    set touched_p 1
}

if {$touched_p} {
    # record that the object has changed
    db_dml update_object "
	update acs_objects set 
	   	last_modified = now(),
	   	modifying_user = :user_id,
		modifying_ip = '[ad_conn peeraddr]'
	where object_id = :object_id
    "

    # Audit the object
    im_audit -object_id $object_id -action "after_update" -comment "After adding members" 
}


# --------------------------------------------------------
# Prepare to send out an email alert
# --------------------------------------------------------

set system_name [ad_system_name]
set object_name [db_string project_name "select acs_object.name(:object_id) from dual"]
set page_title "Notify user"
set context [list $page_title]

set export_vars [export_vars -form {object_id role_id return_url}]
foreach uid $user_id_from_search {
     append export_vars "<input type=hidden name=user_id_from_search value=$uid>\n"
}

set current_user_name [db_string cur_user "select im_name_from_user_id(:user_id) from dual"]
set object_rel_url [db_string object_url "select url from im_biz_object_urls where url_type = 'view' and object_type = :object_type"]
set role_name [db_string role_name "select im_category_from_id(:role_id) from dual" -default "Member"]

# Get the SystemUrl without trailing "/"
set system_url [im_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
set sysurl_len [string length $system_url]
set last_char [string range $system_url $sysurl_len-1 $sysurl_len]
if {"/" eq $last_char} {
    set system_url "[string range $system_url 0 $sysurl_len-2]"
}

set admin_user_id [ad_conn user_id]
set administration_name [db_string admin_name "select im_name_from_user_id(:admin_user_id)"]

set object_url "$system_url$object_rel_url$object_id"

set user_name "%user_name%"
set first_names_from_search "%first_names%"
set last_name_from_search "%last_name%"

if {"" != $notify_asignee && "0" ne $notify_asignee } {
    # Show a textarea to edit the alert at member-add-2.tcl
    ad_return_template
} else {
    ad_returnredirect $return_url
}


set subject_l10n [lang::message::lookup "" $subject_l10n_key "%role_name% of %object_name%"]
set body_l10n_default "Dear %first_names_from_search%,

You have been added as a %role_name%
to %object_name%
in %system_name% at 
%object_url%

Please click on the link above for details.

Best regards,
%current_user_name%
"
set body_l10n [lang::message::lookup "" $body_l10n_key $body_l10n_default]
