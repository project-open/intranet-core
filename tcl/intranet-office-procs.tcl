# /packages/intranet-core/tcl/intranet-office-procs.tcl
#
# Copyright (C) 2004 ]project-open[
# The code is based on work from ArsDigita ACS 3.4 and OpenACS 5.0
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

ad_library {

    Procedures related to offices

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
}


ad_proc -public im_office_status_active {} { return 160 }
ad_proc -public im_office_status_inactive {} { return 161 }

ad_proc -public im_office_type_main {} { return 170 }
ad_proc -public im_office_type_sales {} { return 171 }


# -----------------------------------------------------------
# Office OO methods new, del and name
# -----------------------------------------------------------

ad_proc -public im_office_permissions {user_id office_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $office_id.<BR>
    The permissions depend on whether the office is a companies office or
    an internal office:
    <ul>
      <li>Internal Offices:<br>
	  Are readable by all employees
      <li>Company Offices:<br>
	  Need either global company access permissions
	  or the be the Key account of the respective company.
    </ul>
    Write and administration rights are only for administrators
    and the company key account managers.

} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    # Check if the company is "internal"
    set company_type "unknown"
    set company_id 0
    set company_type [db_0or1row company_type "
select
	im_category_from_id(c.company_type_id) as company_type,
	c.company_id
from
	im_offices o,
	im_companies c
where
	o.office_id = :office_id
	and o.company_id = c.company_id
"]

    if {"" == $company_id || !$company_id} {
	# It is possible that we got here an office without
	# a company.
	# Let's asume they are internal and use the corresponding
	# security check.
	set admin [im_permission $user_id edit_internal_offices]
	set write $admin
	set read [expr {$admin || [im_permission $user_id view_internal_offices]}]
	set view $read
    } else {
	
	# Initialize values with values from company
	im_company_permissions $user_id $company_id view read write admin
    }

    ns_log Notice "im_office_permissions: cust perms: view=$view, read=$read, write=$write, admin=$admin"

    # Now there are three options:
    # NULL: not assigned to any company yet
    # 'internal': An internal office and
    # != 'internal': A companies office

    # Internal office: Allow employees to see the offices and
    # Senior Managers to change them (or similar, as defined
    # in the permission module)
    if {"internal" eq $company_type} {
	set admin [expr {$admin || [im_permission $user_id edit_internal_offices]}]
	set read [expr {$read || [im_permission $user_id view_internal_offices]}]

	if {$user_is_office_admin_p} { set admin 1 }
	if {$user_is_office_member_p} { set read 1}

	if {$admin} { set read 1}
	set write $admin
	ns_log Notice "im_office_permissions: internal perms: view=$view, read=$read, write=$write, admin=$admin"
	return
    }
    
    # A "dangeling" office (without company) - 
    # don't give permissions
    if {0 == $company_id } {
	# Give permissions to everybody?
	set view 1
	set read 1
	set write 1
	set admin 1
	return
    }
}




# -----------------------------------------------------------
# Manage office groups
# -----------------------------------------------------------

ad_proc -callback im_office_after_update -impl im_office_group_manager {
    -object_id
    -status_id
    -type_id
} {
    Callback everytime after an office has been modified.
} {
    ns_log Notice "im_office_after_update -impl im_office_group_manager: Starting callback"

    # Check if the office belongs to a company of type "internal"
    im_security_alert_check_integer -location "ad_proc -callback im_office_after_update -impl im_office_group_manager" -value $object_id
    set company_type_id [util_memoize [list db_string office_company_type "select c.company_type_id from im_companies c, im_offices o where o.company_id = c.company_id and o.office_id = $object_id" -default ""]]

    if {[im_company_type_internal] != $company_type_id} {
	ns_log Notice "im_office_after_update -impl im_office_group_manager: Aborting callback - not an 'internal' office"
	return
    }

    ns_log Notice "im_office_after_update: About to call: 'im_biz_object_group_sweeper -object_id $object_id'"
    im_biz_object_group_sweeper -object_id $object_id
    ns_log Notice "im_office_after_update -impl im_office_group_manager: End callback"
}


ad_proc -callback im_office_view -impl im_office_group_manager {
    -object_id
    -status_id
    -type_id
} {
    Callback everytime an office is viewed.
} {
    ns_log Notice "im_office_view -impl im_office_group_manager: Starting callback"

    # Check if the office belongs to a company of type "internal"
    im_security_alert_check_integer -location "ad_proc -callback im_office_view -impl im_office_group_manager" -value $object_id
    set company_type_id [util_memoize [list db_string office_company_type "select c.company_type_id from im_companies c, im_offices o where o.company_id = c.company_id and o.office_id = $object_id" -default ""]]

    if {[im_company_type_internal] != $company_type_id} {
	ns_log Notice "im_office_view -impl im_office_group_manager: Aborting callback - not an 'internal' office"
	return
    }

    ns_log Notice "im_office_view: About to call: 'im_biz_object_group_sweeper -object_id $object_id'"
    im_biz_object_group_sweeper -object_id $object_id
    ns_log Notice "im_office_view -impl im_office_group_manager: End callback"
}


# -----------------------------------------------------------
# Select a physical location for a company
# -----------------------------------------------------------

ad_proc -public im_company_office_select { 
    { -include_empty_p 0 }
    { -include_empty_name "" }
    select_name 
    default 
    company_id 
    { office_type_id "" } 
} {
    Returns an html select box named $select_name and defaulted to
    $default with the list of all avaiable offices for a company.
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars company_id $company_id
    ns_set put $bind_vars office_type_id $office_type_id

    # Legacy - if there's no EMPTY entry required, set the DEFAULT to the companies main_office 
    if { 0 == $include_empty_p && "" == $default } {
	set default [db_string main_office "select main_office_id from im_companies where company_id = :company_id" -default ""]
    }

    set query "
		select DISTINCT
		        o.office_id,
			o.office_name
		from
			im_offices o
		where
			o.company_id = :company_id
    "
    return [im_selection_to_select_box -translate_p 0 -include_empty_p $include_empty_p -include_empty_name $include_empty_name $bind_vars company_office_select $query $select_name $default]
}

# -----------------------------------------------------------
# 
# -----------------------------------------------------------

namespace eval im_office {

    ad_proc -public new {
	{ -office_name "" }
	{ -office_path "" }
	{ -office_type_id "" }
	{ -office_status_id "" }
	{ -office_id "" } 
	{ -creation_date "" }
	{ -creation_user "" }
	{ -creation_ip "" }
	{ -context_id "" } 
	{ -company_id "" }
    } {
	Creates a new office object. Offices can be either of "Internal"
	company (-> Internal offices) or of regular companies.
	This difference determines the access permissions, because internal
	offices should be seen by all employees, while company offices
	are more sensitive data.

	@author frank.bergmann@project-open.com

	@return <code>office_id</code> of the newly created office

	@param office_name Pretty name for the office
	@param office_path Path for office files in the filestorage
	@param office_type_id Configurable office type used for reporting 
	@param office_status_id Default: "Active": Allows to follow-
	       up through the office acquistion process
	@param others The default optional parameters for OpenACS
	       objects    
    } {
	if { $creation_date eq "" } {
	    set creation_date [db_string get_sysdate "select sysdate from dual"]
        }
        if { $creation_user eq "" } {
            set creation_user [auth::get_user_id]
        }
        if { $creation_ip eq "" } {
            set creation_ip [ns_conn peeraddr]
        }

	# Create the office
	set office_id [db_exec_plsql create_new_office {}]

	# Record the creation
	im_audit -object_type "im_office" -object_id $office_id -action after_create

	return $office_id
    }

}


# ----------------------------------------------------------------------
# Office HTML Components
# ---------------------------------------------------------------------

ad_proc -public im_office_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the office_types in the system
} {
    return [im_category_select "Intranet Office Type" $select_name $default]
}

ad_proc -public im_office_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the office_types in the system
} {
    return [im_category_select "Intranet Office Status" $select_name $default]
}



ad_proc -public im_office_company_component { user_id company_id } {
    Creates a HTML table showing the table of offices related to the
    specified company.
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set office_view_page "/intranet/offices/view"

    set sql "
	select
		o.*,
		im_category_from_id(o.office_type_id) as office_type,
		im_category_from_id(o.office_status_id) as office_status
	from
		im_offices o,
		im_categories c
	where
		o.company_id = :company_id
		and o.office_status_id = c.category_id
		-- and lower(c.category) not in ('inactive')
    "

    set component_html "
	<table cellspacing=1 cellpadding=1>
	<tr class=rowtitle>
	  <td class=rowtitle>[_ intranet-core.Office]</td>
	  <td class=rowtitle>[_ intranet-core.Tel]</td>
	  <td class=rowtitle>[_ intranet-core.Status]</td>
	</tr>
    "

    set ctr 1
    db_foreach office_list $sql {
	append component_html "
		<tr$bgcolor([expr {$ctr % 2}])>
		  <td><A href=\"$office_view_page?office_id=$office_id\">$office_name</A></td>
		  <td>$phone</td>
		  <td>$office_status</td>
		</tr>
        "
	incr ctr
    }
    if {$ctr == 1} {
	append component_html "<tr><td colspan=2>[_ intranet-core.No_offices_found]</td></tr>\n"
    }

    append component_html "
	<tr>
	  <td colspan=99 align=right>
	    <A href=/intranet/offices/>[lang::message::lookup "" intranet-core.Show_all_offices "Show all offices"]</a>
	  </td>
	</tr>
	</table>
    "

    return $component_html
}



ad_proc -public im_office_user_component { 
    current_user_id 
    user_id 
} {
    Creates a HTML table showing the table of offices related to the
    specified user.
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set office_view_page "/intranet/offices/view"
    set subsite_id [ad_conn subsite_id]

    set sql "
	select
		o.*,
		im_category_from_id(o.office_type_id) as office_type
	from
		(select
			o.*,
			m.member_p as permission_member,
			see_all.see_all as permission_all
		from
			acs_rels r,
			( select count(*) as see_all
			  from	acs_object_party_privilege_map
			  where	object_id = :subsite_id
				and party_id = :current_user_id
				and privilege='view_offices_all'
			) see_all,
			im_offices o left outer join
			( select count(rel_id) as member_p,
				object_id_one as object_id
			  from	acs_rels
			  where	object_id_two = :current_user_id
			  group by object_id_one
			) m on (o.office_id = m.object_id)
		where
			r.object_id_one = o.office_id
			and r.object_id_two = :user_id
	        ) o
	where
	        (o.permission_member > 0 OR o.permission_all > 0)
    "

    set component_html "
	<table cellspacing=1 cellpadding=1>
	<tr class=rowtitle>
	  <td class=rowtitle>[_ intranet-core.Office]</td>
	  <td class=rowtitle>[_ intranet-core.Type]</td>
	</tr>
    "

    set ctr 1
    db_foreach office_list $sql {
	append component_html "
		<tr$bgcolor([expr {$ctr % 2}])>
		  <td>
		    <A href=\"$office_view_page?office_id=$office_id\">$office_name</A>
		  </td>
		  <td>
		    $office_type
		  </td>
		</tr>
        "
	incr ctr
    }
    if {$ctr == 1} {
	# Skip the office component completely, because
	# the current_user probably doesn't have permissions
	# to see anything
	# append component_html "<tr><td colspan=2>[_ intranet-core.No_offices_found]</td></tr>\n"

	return ""
    }
    append component_html "</table>\n"
    return $component_html
}



# -----------------------------------------------------------
# Nuke a office
# -----------------------------------------------------------

ad_proc im_office_nuke {
    {-current_user_id 0}
    office_id
} {
    Nuke (complete delete from the database) a office
} {
    ns_log Notice "im_office_nuke office_id=$office_id"
    if {0 == $current_user_id || "" == $current_user_id} { set current_user_id [ad_conn user_id] }

    im_office_permissions $current_user_id $office_id view read write admin
    if {!$admin} { return }

    # Check if referenced by a company
    set company_p [db_string company_p "select count(*) from im_companies where main_office_id = :office_id"]
    if {$company_p} { 
	ns_log Warning "offices/nuke-2: Can't delee office #$office_id because is referenced by a company"
	return 
    }

    im_audit -user_id $current_user_id -object_type "im_office" -object_id $office_id -action before_nuke

    # Permissions
    ns_log Notice "offices/nuke-2: acs_permissions"
    db_dml perms "delete from acs_permissions where object_id = :office_id"

    ns_log Notice "offices/nuke-2: Referencing companies"
    db_dml perms "delete from acs_permissions where object_id = :office_id"

    
    # Forum
    ns_log Notice "offices/nuke-2: im_forum_topic_user_map"
    db_dml forum "
		delete from im_forum_topic_user_map 
		where topic_id in (
			select topic_id 
			from im_forum_topics 
			where object_id = :office_id
		)
    "
    ns_log Notice "offices/nuke-2: im_forum_topics"
    db_dml forum "delete from im_forum_topics where object_id = :office_id"

    ns_log Notice "offices/nuke-2: im_invoices"
    if {[im_table_exists im_invoices]} {
	db_dml forum "update im_invoices set invoice_office_id = null where invoice_office_id = :office_id"
    }

    # Filestorage
    ns_log Notice "offices/nuke-2: im_fs_folder_status"
    db_dml filestorage "
		delete from im_fs_folder_status 
		where folder_id in (
			select folder_id 
			from im_fs_folders 
			where object_id = :office_id
		)
    "
    ns_log Notice "offices/nuke-2: im_fs_folders"
    db_dml filestorage "
		delete from im_fs_folder_perms 
		where folder_id in (
			select folder_id 
			from im_fs_folders 
			where object_id = :office_id
		)
    "
    db_dml filestorage "delete from im_fs_folders where object_id = :office_id"


    ns_log Notice "offices/nuke-2: rels"
    set rels [db_list rels "
		select rel_id 
		from acs_rels 
		where object_id_one = :office_id 
			or object_id_two = :office_id
    "]
    foreach rel_id $rels {
	db_dml del_rels "delete from group_element_index where rel_id = :rel_id"
	db_dml del_rels "delete from im_biz_object_members where rel_id = :rel_id"
	db_dml del_rels "delete from membership_rels where rel_id = :rel_id"
	db_dml del_rels "delete from acs_rels where rel_id = :rel_id"
	db_dml del_rels "delete from acs_objects where object_id = :rel_id"
    }
    
    
    ns_log Notice "offices/nuke-2: party_approved_member_map"
    db_dml party_approved_member_map "
		delete from party_approved_member_map 
		where party_id = :office_id"
    db_dml party_approved_member_map "
		delete from party_approved_member_map 
		where member_id = :office_id"

    db_dml delete_offices "
		delete from im_offices 
		where office_id = :office_id"

}


