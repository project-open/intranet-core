# /packages/intranet-core/tcl/intranet-office-procs.tcl
#
# Copyright (C) 2004 Project/Open
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
	set read [expr $admin || [im_permission $user_id view_internal_offices]]
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
    if {[string equal "internal" $company_type]} {
	set admin [expr $admin || [im_permission $user_id edit_internal_offices]]
	set read [expr $read || [im_permission $user_id view_internal_offices]]

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


namespace eval office {

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

	# -----------------------------------------------------------
	# Check for duplicated unique fields (name & path)
	# We asume the application page knows how to deal with
	# the uniqueness constraint, so we won't generate an error
	# but just return the duplicated item. 
	set office_id 0
	set dup_sql "
select	office_id 
from	im_offices 
where	office_name = :office_name 
	or office_path = :office_path"
	db_foreach dup_offices $dup_sql {  
	    # nope - sets office_id 
	}
	if {0 != $office_id} { 
	    ns_log Notice "office::new: found existing office with same name: $office_id"
	    return $office_id 
	}

	# -----------------------------------------------------------

	set office_id [db_exec_plsql create_new_office {}]
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
	im_category_from_id(o.office_type_id) as office_type
from
	im_offices o,
	im_categories c
where
	o.company_id = :company_id
	and o.office_status_id = c.category_id
	and lower(c.category) not in ('inactive')
"

    set component_html "
<table cellspacing=1 cellpadding=1>
<tr class=rowtitle>
  <td class=rowtitle>Office</td>
  <td class=rowtitle>Tel</td>
</tr>\n"

    set ctr 1
    db_foreach office_list $sql {
	append component_html "
<tr$bgcolor([expr $ctr % 2])>
  <td>
    <A href=\"$office_view_page?office_id=$office_id\">$office_name</A>
  </td>
  <td>
    $phone
  </td>
</tr>\n"
	incr ctr
    }
    if {$ctr == 1} {
	append component_html "<tr><td colspan=2>No offices found</td></tr>\n"
    }

    append component_html "
<tr>
  <td colspan=99 align=right>
    <A href=/intranet/offices/>more ...</a>
  </td>
</tr>
</table>
"

    return $component_html
}



ad_proc -public im_office_user_component { current_user_id user_id } {
    Creates a HTML table showing the table of offices related to the
    specified user.
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set office_view_page "/intranet/offices/view"

    set sql "
select
	o.*,
	im_category_from_id(o.office_type_id) as office_type
from
	im_offices o,
	acs_rels r
where
	r.object_id_one = o.office_id
	and r.object_id_two = :user_id
"

    set component_html "
<table cellspacing=1 cellpadding=1>
<tr class=rowtitle>
  <td class=rowtitle>Office</td>
  <td class=rowtitle>Type</td>
</tr>\n"

    set ctr 1
    db_foreach office_list $sql {
	append component_html "
<tr$bgcolor([expr $ctr % 2])>
  <td>
    <A href=\"$office_view_page?office_id=$office_id\">$office_name</A>
  </td>
  <td>
    $office_type
  </td>
</tr>\n"
	incr ctr
    }
    if {$ctr == 1} {
	append component_html "<tr><td colspan=2>No offices found</td></tr>\n"
    }
    append component_html "</table>\n"

    return $component_html
}


