# /packages/intranet-core/www/admin/cleanup-demo/cleanup-users.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Show all the views

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [ad_conn url] }

set page_title "[_ intranet-core.Nuke_Demo_Users]"
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action "all"
set action_list [list "[_ intranet-core.Nuke_All_Demo_Users]" "[export_vars -base "cleanup-users-2" {return_url action}]" "[_ intranet-core.Nuke_All_Demo_Users]"]
set action_list {}

set elements_list {
  user_id {
    label "[_ intranet-core.User_Id]"
  }
  user_name {
    label "[_ intranet-core.Name]"
    display_template {
	    <a href="@users.user_url@">@users.user_name@</a>
    }
  }
  user_type {
  	label "[_ intranet-core.User_Type]"
  }
  member_state {
  	label "[_ intranet-core.User_Status]"
  }
}

list::create \
        -name user_list \
        -multirow users \
        -key user_id \
        -actions $action_list \
        -elements $elements_list \
	-bulk_actions [list [_ intranet-core.Nuke_Checked_Users] cleanup-users-2 [_ intranet-core.Nuke_Checked_Users]] \
	-bulk_action_export_vars { return_url } \
        -bulk_action_method post \
        -filters {
        	return_url
        }
        
db_multirow -extend {user_url} users get_users "
	select 	u.*,
		im_name_from_user_id(u.user_id) as user_name,
		admin_p.admin_p,
		employee_p.employee_p,
		coalesce(admin_p.admin, '') || 
		coalesce(employee_p.employee , '') || 
		coalesce( customer_p.customer , '') || 
		coalesce(freelance_p.freelance, '') as user_type
	from	cc_users u
	LEFT JOIN
	       	(select	member_id as user_id,
		  	count(*) as admin_p,
			'SysAdmin '::text as admin
		 from	group_distinct_member_map
		 where	group_id = [im_profile_po_admins]
		 group by member_id
		) admin_p
		on u.user_id = admin_p.user_id
	LEFT JOIN
	       	(select	member_id as user_id,
		  	count(*) as employee_p,
			'Employee '::text as employee
		 from	group_distinct_member_map
		 where	group_id = [im_profile_employees]
		 group by member_id
		) employee_p
		on u.user_id = employee_p.user_id
	LEFT JOIN
	       	(select	member_id as user_id,
		  	count(*) as customer_p,
			'Customer '::text as customer
		 from	group_distinct_member_map
		 where	group_id = [im_profile_customers]
		 group by member_id
		) customer_p
		on u.user_id = customer_p.user_id
	LEFT JOIN
	       	(select	member_id as user_id,
		  	count(*) as freelance_p,
			'Freelance '::text as freelance
		 from	group_distinct_member_map
		 where	group_id = [im_profile_freelancers]
		 group by member_id
		) freelance_p
		on u.user_id = freelance_p.user_id
	where	admin_p.admin_p is null
	order by u.user_id DESC
" {
	set user_url [export_vars -base "/intranet/users/view" {user_id return_url}]
}

