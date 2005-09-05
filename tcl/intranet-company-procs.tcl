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
ad_proc -public im_company_status_potential {} { return 41 }
ad_proc -public im_company_status_inquiries {} { return 42 }
ad_proc -public im_company_status_qualifying {} { return 43 }
ad_proc -public im_company_status_quoting {} { return 44 }
ad_proc -public im_company_status_quote_out {} { return 45 }
ad_proc -public im_company_status_active {} { return 46 }
ad_proc -public im_company_status_declined {} { return 47 }
ad_proc -public im_company_status_inactive {} { return 48 }


# Frequently used Company Types
ad_proc -public im_company_type_other {} { return 52 }
ad_proc -public im_company_type_internal {} { return 53 }
ad_proc -public im_company_type_provider {} { return 56 }
ad_proc -public im_company_type_customer {} { return 57 }
ad_proc -public im_company_type_freelance {} { return 58 }
ad_proc -public im_company_type_office_equip {} { return 59 }


# Suitable roles for a company object
ad_proc -public im_company_role_key_account { } { return 1302 }
ad_proc -public im_company_role_member { } { return 1300 }


ad_proc -public im_company_annual_rev_0_1 {} { return 223 }
ad_proc -public im_company_annual_rev_1_10 {} { return 224 }
ad_proc -public im_company_annual_rev_10_100 {} { return 222 }
ad_proc -public im_company_annual_rev_100_ {} { return 225 }


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
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
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
        We can not find information about the specified company."
	return
    }

    # Key Account is also a project manager
    set user_is_key_account_p 0
    if {$user_id == $key_account_id} { set user_is_key_account_p 1 }
    set admin [expr $user_admin_p || $user_is_key_account_p]

    ns_log Notice "im_company_permissions: user_is_key_account_p=$user_is_key_account_p"
    ns_log Notice "im_company_permissions: user_is_admin_p=$user_is_admin_p"
    ns_log Notice "im_company_permissions: user_is_group_member_p=$user_is_group_member_p"
    ns_log Notice "im_company_permissions: user_is_group_admin_p=$user_is_group_admin_p"
    ns_log Notice "im_company_permissions: user_is_employee_p=$user_is_employee_p"
    ns_log Notice "im_company_permissions: user_admin_p=$user_admin_p"

    if {$user_is_group_member_p} { set read 1 }
    if {[im_permission $user_id view_companies_all]} { set read 1 }

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
	Creates a new company including the companies  "Main Office".
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
	or company_path = :company_path"
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
	return $company_id
    }
}


ad_proc -public im_company_internal { } {
    Returns the object_id of the "Internal" company, identifying
    the organization (ower or Project/Open) itself.<br>
    This routine is used during invoicing/payments where documents
    can be both incoming payments (provider=Internal, company=...)
    or outgoing payments (provider=..., company=Internal).
} {
    set company_id [db_string get_interal_company "select company_id from im_companies where company_path='internal'" -default 0]
    if {!$company_id} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_Unable_to_determine_I]<br>
        [_ intranet-core.lt_Maybe_somebody_has_ch]"
    }
    return $company_id
}


ad_proc -public im_company_options { {include_empty 1} } { 
    Cost company options
} {
    set options [db_list_of_lists company_options "
	select company_name, company_id
	from im_companies
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_provider_options { {include_empty 1} } { 
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
	select company_name, company_id
	from im_companies
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


ad_proc -public im_company_contact_select { select_name { default "" } {company_id "201"} } {
    Returns an html select box named $select_name and defaulted to 
    $default with the list of all avaiable contact persons of a given
    company
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars company_id $company_id
    ns_set put $bind_vars customer_group_id [im_customer_group_id]
    ns_set put $bind_vars freelance_group_id [im_freelance_group_id]

    set query "
select DISTINCT
	ur.object_id_two as user_id,
        im_name_from_user_id(ur.object_id_two) as user_name
from
        acs_rels ur,
	acs_rels gr
where
        ur.object_id_one = :company_id
	and ur.object_id_two = gr.object_id_two
	and (
		gr.object_id_one = :customer_group_id
		or gr.object_id_one = :freelance_group_id
	)
"
    return [im_selection_to_select_box -translate_p 0 $bind_vars company_contact_select $query $select_name $default]
}


ad_proc -public im_company_select { select_name { default "" } { status "" } { type "" } { exclude_status "" } } {

    Returns an html select box named $select_name and defaulted to
    $default with a list of all the companies in the system. If status is
    specified, we limit the select box to companies that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).<br>

    New feature 040527: The companies to be shown depend on the users
    permissions: The system should show only the users companies, except
    if the user has the "view_companies_all" permission.

} {
    ns_log Notice "im_company_select: select_name=$select_name, default=$default, status=$status, type=$type, exclude_status=$exclude_status"

    set user_id [ad_get_user_id]
    set bind_vars [ns_set create]
    ns_set put $bind_vars user_id $user_id
    ns_set put $bind_vars default $default
    ns_set put $bind_vars subsite_id [ad_conn subsite_id]

    set where_clause "	and c.company_status_id != [im_company_status_inactive]"

    set perm_sql "
        (	select
		       c.*
        	from
        	        im_companies c,
			acs_rels r
		where
			c.company_id = r.object_id_one
			and r.object_id_two = :user_id
			$where_clause

	UNION
		select
			c.*
		from
			im_companies c
		where
			c.company_id = :default
	)
"

    if {[im_permission $user_id "view_companies_all"]} {
	set perm_sql "im_companies"
    }


set sql "
select
	c.company_id,
	c.company_name
from
	$perm_sql c
where
	1=1
	$where_clause
"

    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	append sql " and c.company_status_id=(select company_status_id from im_company_status where company_status=:status)"
    }

    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars company_status_type $exclude_status]
	append sql " and c.company_status_id in (select company_status_id 
                                                  from im_company_status 
                                                 where company_status not in ($exclude_string)) "
	ns_log Notice "im_company_select: exclude_string=$exclude_string"
    }

    if { ![empty_string_p $type] } {
	ns_set put $bind_vars type $type
	append sql " 
	and c.company_type_id in (
		select 	ct.company_type_id 
		from	im_company_types ct
		where ct.company_type = :type
	UNION
		select 	ch.child_id
		from	im_company_types ct,
			im_category_hierarchy ch
		where
			ch.parent_id = ct.company_type_id
			and ct.company_type = :type
	)"
    }

    append sql " order by lower(c.company_name)"

    return [im_selection_to_select_box -translate_p 0 $bind_vars "company_status_select" $sql $select_name $default]
}

