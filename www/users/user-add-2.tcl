# /packages/intranet-core/www/users/user-add-2.tcl
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

ad_page_contract {
    Processes a new user created by an admin
    @cvs-id $Id$
} -query {
    user_id
    password
    {return_url "/acs-admin/users"}
} -properties {
    context:onevalue
    export_vars:onevalue
    system_name:onevalue
    system_url:onevalue
    first_names:onevalue
    last_name:onevalue
    email:onevalue
    password:onevalue
    administration_name:onevalue
}


set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id add_users]} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_no_rights_to]"
    return
}
set admin_user_id [ad_verify_and_get_user_id]
db_1row user_info "
	select	*
	from	cc_users
	where	user_id = :user_id
"

# Check that we really just created this user...
if {$creation_user != $admin_user_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_no_rights_to]"
    return
}



if { [empty_string_p $password] } {
    set password [ad_generate_random_string]
}

set administration_name [db_string admin_name "select im_name_from_user_id(:admin_user_id)"]
set context [list [list "./" "[_ intranet-core.Users]"] "[_ intranet-core.Notify_added_user]"]
set system_name [ad_system_name]
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]
set object_url ""


ad_return_template
