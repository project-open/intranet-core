# /packages/intranet-core/tcl/intranet-company-components.tcl
#
# Copyright (C) 2004 various parties
# The code is based on work from ArsDigita ACS 3.4
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
    Bring together all "components" (=HTML + SQL code) related to Companies.
    
    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
}

# -----------------------------------------------------------
# Category Constants
# -----------------------------------------------------------

# Frequently used Company Stati
ad_proc -public im_company_status_active_or_potential {} { return 40 }
ad_proc -public im_company_status_potential {} { return 41 }
ad_proc -public im_company_status_inquiries {} { return 42 }
ad_proc -public im_company_status_qualifying {} { return 43 }
ad_proc -public im_company_status_quoting {} { return 44 }
ad_proc -public im_company_status_quote_out {} { return 45 }
ad_proc -public im_company_status_active {} { return 46 }
ad_proc -public im_company_status_declined {} { return 47 }
ad_proc -public im_company_status_inactive {} { return 48 }
ad_proc -public im_company_status_deleted {} { return 49 }


# Frequently used Company Types
ad_proc -public im_company_type_unknown {} { return 51 }
ad_proc -public im_company_type_other {} { return 52 }
ad_proc -public im_company_type_internal {} { return 53 }
ad_proc -public im_company_type_provider {} { return 56 }
ad_proc -public im_company_type_customer {} { return 57 }
ad_proc -public im_company_type_freelance {} { return 58 }
ad_proc -public im_company_type_office_equip {} { return 59 }

ad_proc -public im_company_type_partner {} { 
    return [db_string parter_type "
	select category_id
	from im_categories
	where category_type = 'Intranet Company Type'
	      and category = 'Partner'
    " -default 0]
}


# Suitable roles for a company object
ad_proc -public im_company_role_key_account { } { return 1302 }
ad_proc -public im_company_role_member { } { return 1300 }


# Annual revenues constants for companies
ad_proc -public im_company_annual_rev_0_1 {} { return 223 }
ad_proc -public im_company_annual_rev_1_10 {} { return 224 }
ad_proc -public im_company_annual_rev_10_100 {} { return 222 }
ad_proc -public im_company_annual_rev_100_ {} { return 225 }


# -----------------------------------------------------------
# Caching procs for companies
# -----------------------------------------------------------


namespace eval im_company {

    ad_proc -public flush_cache { } { 
	Remove all cache entries for debugging purposes.
	This should not be necessary during normal operations.
    } {
	foreach name [ns_cache names im_company] {
	    ns_cache flush im_company $name
	}
    }


    # -----------------------------------------------------------
    # Returns an option list of companies:
    # (company_name - company_id) tuples
    #
    ad_proc -public company_options { 
	{-user_id ""}
	{-status_id "" }
	{-type_id "" }
	{-exclude_status_id "" }
	{-always_include_company_id "" }
    } {
	Returns a list of company_name - company_id tuples for the
	given parameters.
	This procedure relies that changes to companies will be 
	reported to this module.
    } {

	if {"" == $user_id} { set user_id [ad_get_user_id] }
	
	# Check if we have calculated this result already
	set key [list company_options $user_id $status_id $type_id $exclude_status_id $always_include_company_id]
	if {[ns_cache get im_company $key value]} { return $value }

	# Calculate the options
	set company_options [company_options_not_cached -user_id $user_id -status_id $status_id -type_id $type_id -exclude_status_id $exclude_status_id -always_include_company_id $always_include_company_id]

	# Store the value in the cache
        ns_cache set im_company $key $company_options

	return $company_options
    }

    ad_proc -public company_options_not_cached { 
	-user_id:required
	{-status_id "" }
	{-type_id "" }
	{-exclude_status_id "" }
	{-always_include_company_id "" }
    } {
	Returns a list of company_name - company_id tuples for the
	given parameters.
	This procedure relies that changes to companies will be 
	reported to this module.
    } {
	# Security checks
	im_security_alert_check_integer -location "company_options_not_cached" -value $user_id
	im_security_alert_check_integer -location "company_options_not_cached" -value $status_id
	im_security_alert_check_integer -location "company_options_not_cached" -value $type_id
	im_security_alert_check_integer -location "company_options_not_cached" -value $exclude_status_id
	im_security_alert_check_integer -location "company_options_not_cached" -value $always_include_company_id

	if {"" == $always_include_company_id} { set always_include_company_id 0 }

	# Build the SQL conditions
	set criteria [list]
	lappend criteria "c.company_status_id not in ([join [im_sub_categories [im_company_status_inactive]] ","])"
	
	if {"" != $status_id} {
	    im_security_alert_check_integer -value $status_id -location "company_options_not_cached"
	    lappend criteria "c.company_status_id in ([join [im_sub_categories $status_id] ","])"
	}
	
	if {"" != $exclude_status_id} {
	    im_security_alert_check_integer -value $exclude_status_id -location "company_options_not_cached"
	    lappend criteria "c.company_status_id not in ([join [im_sub_categories $exclude_status_id] ","])"
	}
	
	if {"" != $type_id} {
	    im_security_alert_check_integer -value $type_id -location "company_options_not_cached"
	    lappend criteria "c.company_type_id in ([join [im_sub_categories $type_id] ","])"
	}
    
        set where_clause [join $criteria " and\n\t\t"]
        if { ![empty_string_p $where_clause] } { set where_clause " and $where_clause" }

        # Permission SQL: Normal users can see only "their" companies
	set perm_sql "
		(       select	c.*
			from	im_companies c,
				acs_rels r
			where	c.company_id = r.object_id_one
				and r.object_id_two = :user_id
				$where_clause
		UNION
			select	c.*
			from	im_companies c
			where	c.company_id in ([join $always_include_company_id ","])
		)
	"

        # Certain users can see all companies. This simplified the permissions...
	if {[im_permission $user_id "view_companies_all"]} {
	    set perm_sql "im_companies"
	}

        # Pull out all suitable companies
	set company_sql "
		select	c.company_name,
			c.company_id
		from	$perm_sql c
		where	1=1
			$where_clause
		order by lower(trim(c.company_name))
	"

	set options [db_list_of_lists company_options $company_sql]
	return $options
    }
}



# -----------------------------------------------------------
# 
# -----------------------------------------------------------

ad_proc -public im_company_link_tr {user_id company_id company_name title} {
    Returns a formatted HTML component TR - TD - text - /TD - /TR
    containing a link to a company depending on the permissions
    of the current user.<br>
    Returns "" if the current user has no rights to see the company.
} {
    im_company_permissions $user_id $company_id view read write admin
    if {!$view} { return "" }

    # Default link for "view" - show only the name
    set link $company_name
    if {$read} {
	set link "<A HREF='/intranet/companies/view?company_id=$company_id'>$company_name</A>"
    }
    return "
<tr>
  <td>$title</td>
  <td>$link</td>
</tr>"
}


ad_proc -public im_company_permissions {user_id company_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $company_id
} {
    set debug 0

    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    if {0 == $company_id} { return }
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [im_profile::member_p -profile_id [im_wheel_group_id] -user_id $user_id]
    set user_is_group_member_p [im_biz_object_member_p $user_id $company_id]
    set user_is_group_admin_p [im_biz_object_admin_p $user_id $company_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
    set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

    # Get basic company information
    if {[catch {
	db_1row company_info "
		select 
			c.*,
			c.manager_id as key_account_id
		from
			im_companies c
		where
			company_id = :company_id
	"
    } catch_err]} {
	ad_return_complaint 1 "Bad Company:<br>
        We can not find information about the company '$company_id'."
	return
    }

    # Key Account is also a project manager
    set user_is_key_account_p 0
    if {$user_id == $key_account_id} { set user_is_key_account_p 1 }
    set admin [expr $user_admin_p || $user_is_key_account_p]

    if {$debug} {
	ns_log Notice "im_company_permissions: user_is_key_account_p=$user_is_key_account_p"
	ns_log Notice "im_company_permissions: user_is_admin_p=$user_is_admin_p"
	ns_log Notice "im_company_permissions: user_is_group_member_p=$user_is_group_member_p"
	ns_log Notice "im_company_permissions: user_is_group_admin_p=$user_is_group_admin_p"
	ns_log Notice "im_company_permissions: user_is_employee_p=$user_is_employee_p"
	ns_log Notice "im_company_permissions: user_admin_p=$user_admin_p"
    }

    if {$user_is_group_member_p} { set read 1 }
    if {[im_permission $user_id view_companies_all]} { set read 1 }
    if {[im_permission $user_id edit_companies_all]} { set admin 1 }

    # All employees have the right to see the "internal" company
    if {$user_is_employee_p && [string equal "internal" $company_path]} { 
	set read 1 
    }
    
    if {$admin} {
	set read 1
	set write 1
    }
    if {$read} { set view 1 }
}

namespace eval company {

    ad_proc new {
        -company_name
        -company_path
        -main_office_id
	{ -company_type_id "" }
	{ -company_status_id "" }
	{ -creation_date "" }
	{ -creation_user "" }
	{ -creation_ip "" }
	{ -context_id "" }
	{ -company_id "" }
    } {
	Creates a new company including the companies "Main Office".
	@author frank.bergmann@project-open.com

	@return <code>company_id</code> of the newly created company

	@param company_name Pretty name for the company
	@param company_path Path for company files in the filestorage
	@param main_office_id Optional: Use this office as the companies
	       main office.
	@param company_type_id Default: "Other": Configurable company
	       type used for reporting only
	@param company_status_id Default: "Active": Allows to follow-
	       up through the company acquistion process
	@param others The default optional parameters for OpenACS
	       objects
    } {
	# -----------------------------------------------------------
	# Check for duplicated unique fields (name & path)
	# We asume the application page knows how to deal with
	# the uniqueness constraint, so we won't generate an error
	# but just return the duplicated item. 
	set dup_sql "
		select	company_id 
		from	im_companies 
		where	company_name = :company_name 
			or company_path = :company_path
	"
	set cid 0
	db_foreach dup_companies $dup_sql { set cid $company_id }
	if {0 != $cid} { return $cid }

	# -----------------------------------------------------------

        if { [empty_string_p $creation_date] } {
            set creation_date [db_string get_sysdate "select sysdate from dual"]
        }
        if { [empty_string_p $creation_user] } {
            set creation_user [auth::get_user_id]
        }
        if { [empty_string_p $creation_ip] } {
            set creation_ip [ns_conn peeraddr]
        }

	set company_id [db_exec_plsql create_new_company {}]

	# Record the action
        im_audit -object_type "im_company" -object_id $company_id -action after_create

	return $company_id
    }
}


ad_proc -public im_company_internal { } {
    Returns the object_id of the "Internal" company, identifying
    the organization itself.<br>

    This routine is used during invoicing/payments where documents
    can be both incoming payments (provider=Internal, company=...)
    or outgoing payments (provider=..., company=Internal).
} {
    set company_id [util_memoize [list im_company_internal_helper]]
    return $company_id
}

ad_proc -public im_company_internal_helper { } {
    Returns the object_id of the "Internal" company, identifying
    the organization itself.<br>
} {
    set company_id [db_string get_internal_company "select company_id from im_companies where company_path='internal'" -default 0]
    if {!$company_id} {
	util_memoize_flush_regexp "im_company_internal"
	ad_return_complaint 1 "<li>[_ intranet-core.lt_Unable_to_determine_I]<br>
        [_ intranet-core.lt_Maybe_somebody_has_ch]"
    }
    return $company_id
}


ad_proc -public im_company_freelance { } {
    Returns the object_id of the "Freelance" company, identifying
    default setting for foreelance companies.

    This routine is used during invoicing/payments for
    default information such as Trados Matrix and price list.
} {
    set company_id [util_memoize [list im_company_freelance_helper]]
}

ad_proc -public im_company_freelance_helper { } {
    Returns the object_id of the "Freelance" company, identifying
    default setting for foreelance companies.
} {
    set company_id [db_string get_default_freelance_company "select company_id from im_companies where company_path='default_freelance'" -default 0]

    if {!$company_id} {
	util_memoize_flush_regexp "im_company_freelance_helper"
	ns_log Error "im_company_freelance: Did not find a company with path 'default_freelance'. Using 'internal' instead."
	return [im_company_internal]
    }
    return $company_id
}


ad_proc -public im_provider_options { {include_empty 1} } { 
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
	select company_name, company_id
	from im_companies order by company_name
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}


ad_proc -public im_company_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the project_types in the system
} {
    return [im_category_select "Intranet Company Type" $select_name $default]
}


ad_proc -public im_company_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the company status_types in the system
} {
    return [im_category_select "Intranet Company Status" $select_name $default]
}


ad_proc -public im_company_contact_select { select_name { default "" } {company_id ""} } {
    Returns an html select box named $select_name and defaulted to 
    $default with the list of all avaiable contact persons of a given
    company
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars default_id $default
    ns_set put $bind_vars company_id $company_id
    ns_set put $bind_vars customer_group_id [im_customer_group_id]
    ns_set put $bind_vars freelance_group_id [im_freelance_group_id]

    set query "
	select DISTINCT
		u.user_id,
		im_name_from_user_id(u.user_id) as user_name
	from
		cc_users u,
		group_distinct_member_map m,
		acs_rels ur
	where
		u.member_state = 'approved'
		and u.user_id = m.member_id
		and m.group_id in (:customer_group_id, :freelance_group_id)
		and u.user_id = ur.object_id_two
		and ur.object_id_one = :company_id
		and ur.object_id_one != 0
    "

    # Include the default user in the list, even if he's not a member
    # of the company
    if {"" != $default} {
	append query "
    UNION
	select	:default_id as user_id,
		im_name_from_user_id(:default_id) as user_name
	"
    }

    set query "select * from ($query) t order by user_name"

    return [im_selection_to_select_box -translate_p 0 $bind_vars company_contact_select $query $select_name $default]
}



# -----------------------------------------------------------
# Company "select" and "options"
# -----------------------------------------------------------


ad_proc -public im_company_options {
    {-include_empty_p 1}
    {-include_empty_name "-- Please_select --" }
    {-status_id "" }
    {-status "" }
    {-type_id "" }
    {-type "" }
    {-exclude_status_id "" }
    {-exclude_status "" }
    {default 0}
} {
    Cost company options
} {
    set user_id [ad_get_user_id]
    if {"" != $status} { set status_id [im_id_from_category $status "Intranet Company Status"] }
    if {"" != $exclude_status} { set exclude_status_id [im_id_from_category $exclude_status "Intranet Company Status"] }
    if {"" != $type} { set type_id [im_id_from_category $type "Intranet Company Type"] }

    # Get the options
    set company_options [im_company::company_options \
		     -user_id $user_id \
		     -status_id $status_id \
		     -type_id $type_id \
		     -exclude_status_id $exclude_status_id \
		     -always_include_company_id $default \
    ]
    if {"" != $include_empty_p} { set company_options [linsert $company_options 0 [list $include_empty_name ""]] }
    return $company_options
}


ad_proc -public im_company_select { 
    {-include_empty_p 1}
    {-include_empty_name "-- Please_select --" }
    {-tag_attributes {} }
    select_name 
    { default "" } 
    { status "" } 
    { type "" } 
    { exclude_status "" } 
} {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the companies in the system. If status is
    specified, we limit the select box to companies that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).<br>

    @param tag_attributes key-value-key-value... list of attributes to be included in the tag.
} {
    ns_log Notice "im_company_select: select_name=$select_name, default=$default, status=$status, type=$type, exclude_status=$exclude_status"

    set company_options [im_company_options \
			     -include_empty_p $include_empty_p \
			     -include_empty_name $include_empty_name \
			     -status $status \
			     -type $type \
			     -exclude_status $exclude_status \
			     $default \
    ]
    return [im_options_to_select_box $select_name $company_options $default $tag_attributes]
}



# -----------------------------------------------------------
# Nuke a company
# -----------------------------------------------------------


ad_proc im_company_nuke {
    {-current_user_id 0}
    company_id
} {
    Nuke (complete delete from the database) a company
} {
    ns_log Notice "im_company_nuke company_id=$company_id"

    # Use a predefined user_id to avoid a call to ad_get_user_id.
    # ad_get_user_id's connection isn't defined during a DELETE REST request.
    if {0 == $current_user_id} { 
	ns_log Notice "im_company_nuke: No current_user_id specified - using ad_get_user_id"
	set current_user_id [ad_get_user_id] 
    }

    # Log the action
    im_audit -object_type "im_company" -object_id $company_id -action before_delete

    set company_exists_p [db_string exists "select count(*) from im_companies where company_id = :company_id"]
    if {!$company_exists_p} { return }

    im_company_permissions $current_user_id $company_id view read write admin
    if {!$admin} { return }


    # ---------------------------------------------------------------
    # Delete
    # ---------------------------------------------------------------
    
    # if this fails, it will probably be because the installation has 
    # added tables that reference the users table

    # Delete the projects for this company
    set companies_projects_sql "
	select project_id
	from im_projects
	where company_id = :company_id"
    db_foreach delete_projects $companies_projects_sql {
	im_project_nuke -current_user_id $current_user_id $project_id
    }

    # Delete the offices for this company
    set companies_offices_sql "
	select	office_id
	from	im_offices o,
		acs_rels r
	where	r.object_id_one = o.office_id
		and r.object_id_one = :company_id
    UNION
	select	office_id
	from	im_offices o
	where	company_id = :company_id
    "
    db_foreach delete_offices $companies_offices_sql {
	db_dml unlink_offices "update im_companies set main_office_id = (select min(office_id) from im_offices) where main_office_id = :office_id"
	im_office_nuke -current_user_id $current_user_id $office_id
    }

    db_transaction {
    
	# Permissions
	ns_log Notice "companies/nuke-2: acs_permissions"
	db_dml perms "delete from acs_permissions where object_id = :company_id"
	

	# ----------- Costs & Payments --------------------------------

	# Deleting cost entries in acs_objects that are "dangeling", i.e. that don't have an
	# entry in im_costs. These might have been created during manual deletion of objects
	# Very dirty...
	ns_log Notice "companies/nuke-2: dangeling_costs"
	db_dml dangeling_costs "
		delete from acs_objects 
		where	object_type = 'im_cost' 
			and object_id not in (select cost_id from im_costs)"
	
	# Payments
	db_dml delete_payments1 "
		delete	from im_payments 
		where	(company_id = :company_id OR provider_id = :company_id)
			
	"
	db_dml delete_payments "
		delete	from im_payments 
		where	cost_id in (
			select	c.cost_id
			from	im_costs c
			where	(c.customer_id = :company_id or c.provider_id = :company_id)
		)
	"

	# Costs
	set cost_infos [db_list_of_lists costs "
		select	c.cost_id, object_type 
		from	im_costs c, acs_objects o 
		where	c.cost_id = o.object_id and 
			(c.customer_id = :company_id or c.provider_id = :company_id)
	"]
	foreach cost_info $cost_infos {
	    set cost_id [lindex $cost_info 0]
	    set object_type [lindex $cost_info 1]

	    im_audit -object_type $object_type -object_id $cost_id -action before_delete -comment "Nuking cost as part of nuking company \#$company_id"
	    im_exec_dml del_cost "${object_type}__delete($cost_id)"
	}

	
	# Costs
	set cost_infos [db_list_of_lists costs "
		select cost_id, object_type 
		from im_costs, acs_objects 
		where cost_id = object_id 
		      and (customer_id = :company_id or provider_id = :company_id)
	"]
	foreach cost_info $cost_infos {
	    set cost_id [lindex $cost_info 0]
	    set object_type [lindex $cost_info 1]
	    ns_log Notice "companies/nuke-2: deleting cost: ${object_type}__delete($cost_id)"

	    im_audit -object_type $object_type -object_id $cost_id -action before_delete -comment "Nuking cost as part of nuking company \#$company_id."
	    im_exec_dml del_cost "${object_type}__delete($cost_id)"
	}
	
	
	# Forum
	ns_log Notice "companies/nuke-2: im_forum_topic_user_map"
	db_dml forum "
		delete from im_forum_topic_user_map 
		where topic_id in (
			select topic_id 
			from im_forum_topics 
			where object_id = :company_id
		)
	"
	ns_log Notice "companies/nuke-2: im_forum_topics"
	db_dml forum "delete from im_forum_topics where object_id = :company_id"

	# Filestorage
	ns_log Notice "companies/nuke-2: im_fs_files"
	db_dml del_files "
		delete from im_fs_files
		where folder_id in (
			select	folder_id
			from	im_fs_folders
			where	object_id = :company_id
		)
	"

	ns_log Notice "companies/nuke-2: im_fs_folder_status"
	db_dml filestorage "
		delete from im_fs_folder_status 
		where folder_id in (
			select folder_id 
			from im_fs_folders 
			where object_id = :company_id
		)
	"
	ns_log Notice "companies/nuke-2: im_fs_folders"
	db_dml filestorage "
		delete from im_fs_folder_perms 
		where folder_id in (
			select folder_id 
			from im_fs_folders 
			where object_id = :company_id
		)
	"



	db_dml filestorage "delete from im_fs_folders where object_id = :company_id"


	ns_log Notice "companies/nuke-2: rels"
	set rels [db_list rels "
		select rel_id 
		from acs_rels 
		where object_id_one = :company_id 
			or object_id_two = :company_id
	"]
	foreach rel_id $rels {
	    db_dml del_rels "delete from group_element_index where rel_id = :rel_id"
	    db_dml del_rels "delete from im_biz_object_members where rel_id = :rel_id"
	    db_dml del_rels "delete from membership_rels where rel_id = :rel_id"
	    db_dml del_rels "delete from acs_rels where rel_id = :rel_id"
	    db_dml del_rels "delete from acs_objects where object_id = :rel_id"
	}

	
	ns_log Notice "companies/nuke-2: party_approved_member_map"
	db_dml party_approved_member_map "
		delete from party_approved_member_map 
		where party_id = :company_id"
	db_dml party_approved_member_map "
		delete from party_approved_member_map 
		where member_id = :company_id"

	# ----------- Translation --------------------------------
	db_dml delete_trans_prices "
		delete from im_trans_prices
		where company_id = :company_id
	"


	# ----------- Timesheet --------------------------------
	db_dml delete_timesheet_prices "
		delete from im_timesheet_prices
		where company_id = :company_id
	"


	# ----------- Delete the company --------------------------------
	db_dml delete_companies "
		delete from im_companies 
		where company_id = :company_id"

    } on_error {

	set detailed_explanation ""
	if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	    
	    set sql "select table_name from user_constraints 
		     where constraint_name=:constraint_name"
	    db_foreach user_constraints_by_name $sql {
		set detailed_explanation "<p>[_ intranet-core.lt_It_seems_the_table_we]"
	    }
	}
	return "$detailed_explanation<br><pre>$errmsg</pre>"
    }
    return
}

ad_proc -public im_company_find_or_create_main_office {
    -company_name
} {
    set office_name "$company_name Main Office"
    set office_path "${company_name}_main_office"

    set office_id [db_string office_id "select office_id from im_offices where office_path=:office_path" -default 0]
    if {!$office_id} {
	set office_id [office::new \
		-office_name	$office_name \
		-office_path	$office_path \
		-office_status_id [im_office_status_active] \
		-office_type_id [im_office_type_main] \
	]
    }
    return $office_id
}


ad_proc -public im_company_find_or_create {
    -company_name
    { -company_type_id 0 }
    { -company_status_id 0 }
} {
    if {$company_name==""} { return 0 }

    if {0 == $company_type_id} { set company_type_id [im_company_type_other] }
    if {0 == $company_status_id} { set company_status_id [im_company_status_active] }

    set company_path [string tolower [string trim $company_name]]
    set company_path [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $company_path]

    set company_id [db_string find_company "select company_id from im_companies where company_path=:company_path" -default 0]
	
    if {!$company_id} {
	set office_id [im_company_find_or_create_main_office -company_name $company_name]

	set company_id [company::new \
           -company_name	$company_name \
           -company_path	$company_path \
           -main_office_id	$office_id \
           -company_type_id     $company_type_id \
           -company_status_id   $company_status_id \
        ]
    }

    return $company_id
}


ad_proc -public im_company_info_component {
    company_id
    return_url
} {
    returns company information
} {
    set params [list [list base_url "intranet-core"] [list company_id $company_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/company-info"]
    return [string trim $result]
}


ad_proc -public im_company_projects_component {
    company_id
    return_url
} {
    returns a list of projects associated with the company

    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-30
} {
    set params [list [list base_url "intranet-core"] [list company_id $company_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/company-projects"]
    return [string trim $result]
}


ad_proc -public im_company_employees_component {
    company_id
    return_url
} {
    returns a list of employees associated with the company
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-30
} {
    set params [list [list base_url "intranet-core"] [list company_id $company_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/company-employees"]
    return [string trim $result]
}


ad_proc -public im_company_contacts_component {
    company_id
    return_url
} {
    returns a list of contacts (clients) associated with the company
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-30
} {
    set params [list [list base_url "intranet-core"] [list company_id $company_id] [list return_url $return_url]]
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/company-contacts"]
    return [string trim $result]
}


