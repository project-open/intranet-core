# /www/intranet/customers/view.tcl
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
    View all info regarding one customer

    @param customer_id the customer_id of this customer

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)

} {
    customer_id:integer
    show_all_correspondance_comments:integer,optional
    {forum_order_by ""}
    {forum_view_name "forum_list_project"}
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_group_member_p [ad_user_group_member $customer_id $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_is_group_admin_p [im_can_user_administer_group $customer_id $user_id]
set user_is_employee_p [im_user_is_employee_p $user_id]
set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

set return_url [im_url_with_query]
set current_url [ns_conn url]
set context_bar [ad_context_bar [list ./ "Clients"] "One customer"]

# Key Account is also a project manager
set key_account_id [db_string get_key_account "
select manager_id from im_customers where customer_id=:customer_id" -default 0]
set user_is_key_account_p 0
if {$user_id == $key_account_id} { set user_is_key_account_p 1 }
set user_admin_p [expr $user_admin_p || $user_is_key_account_p]

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

ns_log Notice "key_account_id=$key_account_id"
ns_log Notice "user_is_key_account_p=$user_is_key_account_p"



# Check View Permissions: This should never be executed, because
# unprivileged users should't even see the link to this page...
if {!$user_is_group_member_p && ![im_permission $user_id view_customers]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."
}


db_1row customer_get_info "
select 
	c.customer_name,
	c.customer_path,
	c.note, 
	c.vat_number,
	c.customer_path, 
	c.billable_p,
	im_name_from_user_id(c.primary_contact_id) as primary_contact_name,
	im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
	c.manager_id,
	im_name_from_user_id(c.manager_id) as manager,
	primary_contact_id,
	accounting_contact_id,
	im_category_from_id(c.customer_status_id) as customer_status,
	im_category_from_id(c.customer_type_id) as customer_type,
	c.annual_revenue_id,
	referral_source,
	to_char(start_date,'Month DD, YYYY') as start_date, 
	contract_value, 
	site_concept,
        o.phone,
        o.fax,
        o.address_line1,
        o.address_line2,
        o.address_city,
        o.address_postal_code,
        o.address_country_code,
	cc.country_name
from 
	im_customers c,
	im_offices o,
	country_codes cc
where 
        c.customer_id = :customer_id
	and c.main_office_id = o.office_id(+)
	and o.address_country_code = cc.iso(+)
"

set page_title $customer_name
set left_column ""

# Show customer details only to privileged users or to users
# assigned as key accounts.
set see_details [expr [im_permission $user_id view_customer_details] || $user_admin_p]
set see_details [expr $see_details || $user_is_group_member_p]
 
append left_column "
<table border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>
      Client Details
    </td>
  </tr>
  <tr class=rowodd><td>Name</td><td>$customer_name</td></tr>
  <tr class=roweven><td>Path</td><td>$customer_path</td></tr>
  <tr class=rowodd><td>Status</td><td>$customer_status</td></tr>"

if {$see_details} {
    append left_column "
  <tr class=roweven><td>Client Type</td><td>$customer_type</td></tr>
  <tr class=rowodd><td>Key Account</td><td><a href=[im_url_stub]/users/view?user_id=$manager_id>$manager</a></td></tr>
  <tr class=rowodd><td>Referral source</td><td>$referral_source</td></tr>
  <tr class=roweven><td>Billable?</td><td> [util_PrettyBoolean $billable_p]</td></tr>
  <tr class=rowodd><td>Phone</td><td>$phone</td></tr>
  <tr class=roweven><td>Fax</td><td>$fax</td></tr>
  <tr class=rowodd><td>Address1</td><td>$address_line1</td></tr>
  <tr class=roweven><td>Address2</td><td>$address_line2</td></tr>
  <tr class=rowodd><td>City</td><td>$address_city</td></tr>
  <tr class=roweven><td>Postal Code</td><td>$address_postal_code</td></tr>
  <tr class=rowodd><td>Country</td><td>$country_name</td></tr>\n"
    if {![empty_string_p $site_concept]} {
	# Add a "http://" before the web site if it starts with "www."...
	if {[regexp {www\.} $site_concept]} { set site_concept "http://$site_concept" }
	append left_column "
  <tr class=rowodd><td>Web Site</td><td><A HREF=\"$site_concept\">$site_concept</A></td></tr>\n"
    }
    append left_column "
  <tr class=rowodd><td>VAT Number</td><td>$vat_number</td></tr>"

# ------------------------------------------------------
# Primary Contact
# ------------------------------------------------------

    set primary_contact_text ""
    set limit_to_users_in_group_id [im_employee_group_id]
    if { [empty_string_p $primary_contact_id] } {
	
	if { $user_admin_p } {
	    set primary_contact_text "<a href=primary-contact?[export_url_vars customer_id limit_to_users_in_group_id]>Add primary contact</a>\n"
	} else {
	    set primary_contact_text "<i>none</i>"
	}

    } else {

	append primary_contact_text "<a href=/intranet/users/view?user_id=$primary_contact_id>$primary_contact_name</a>"

	if { $user_admin_p } {
	    append primary_contact_text "
	(<a href=primary-contact?[export_url_vars customer_id limit_to_users_in_group_id]>[im_gif turn "Change the primary contact"]</a> | <a href=primary-contact-delete?[export_url_vars customer_id return_url]>[im_gif delete "Delete the primary contact"]</a>)\n"
	}
    }

    append left_column "<tr class=roweven><td>Primary contact</td><td>$primary_contact_text</td></tr>"


# ------------------------------------------------------
# Accounting Contact
# ------------------------------------------------------

    set accounting_contact_text ""
    set limit_to_users_in_group_id [im_employee_group_id]
    if { [empty_string_p $accounting_contact_id] } {
	
	if { $user_admin_p } {
	    set accounting_contact_text "<a href=accounting-contact?[export_url_vars customer_id limit_to_users_in_group_id]>Add accounting contact</a>\n"
	} else {
	    set accounting_contact_text "<i>none</i>"
	}

    } else {

	append accounting_contact_text "<a href=/intranet/users/view?user_id=$accounting_contact_id>$accounting_contact_name</a>"
	if { $user_admin_p } {
	    append accounting_contact_text "    (<a href=accounting-contact?[export_url_vars customer_id limit_to_users_in_group_id]>[im_gif turn "Change the accounting contact"]</a> | <a href=accounting-contact-delete?[export_url_vars customer_id return_url]>[im_gif delete "Delete the accounting contact"]</a>)\n"
	}
    }

    append left_column "<tr class=roweven><td>Accounting contact</td><td>$accounting_contact_text</td></tr>"


# ------------------------------------------------------
# Continuation ...
# ------------------------------------------------------

    append left_column "<tr class=rowodd><td>Start Date</td><td>$start_date</td></tr>\n"

    #if { ![empty_string_p $contract_value] } {
    #   append left_column "<tr><td>Contract Value</td><td>\$[util_commify_number $contract_value] K</td></tr>\n"
    #}
    if { ![empty_string_p $note] } {
	append left_column "<tr><td>Notes</td><td><font size=-1>$note</font>\n</td></tr>\n"
    }


    if { [ad_parameter EnabledP ischecker 0] } {
	append left_column "  <tr><td>Machines: </td><td> \n<ul>\n"
	foreach machine [is_machine_list_for_group $customer_id] {
	    set hostname [lindex $machine 1]
	    set machine_id [lindex $machine 0]
	    append left_column "<li><a href=/ischecker/machine-view?[export_url_vars machine_id]>$hostname</a><font size=-1> (<a href=/ischecker/group-machine-map-delete?[export_url_vars customer_id machine_id]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]>delete</a>)</font>"
	}
	append left_column "
	<li><a href=/ischecker/group-machine-map?[export_url_vars customer_id]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]&pretty_name=[ns_urlencode $customer_name]>Add a machine</a>
	</ul>
	</td></tr>\n
	<tr><td>Annual Revenue</td><td>$annual_revenue_id</td></tr>\n"
    }
}

if {$user_admin_p} {
    append left_column "
	<tr><td>&nbsp;</td><td>
	<form action=new method=POST>
	[export_form_vars customer_id]
	<input type=submit value='Edit'>
	</form></td></tr>"
}

append left_column "</table>"


# ------------------------------------------------------
# Customer Project List
# ------------------------------------------------------

set sql "
select
	p.*,
	1 as llevel
from
	im_projects p
where 
	p.customer_id=:customer_id
order by p.project_nr
"

set projects_html ""
set current_level 1
set ctr 1
set max_projects 15
db_foreach customer_list_active_projects $sql  {
    ns_log Notice "name=$project_name"
    ns_log Notice "level=$llevel"

    if { $llevel > $current_level } {
	append projects_html "  <ul>\n"
	incr current_level
    } elseif { $llevel < $current_level } {
	append projects_html "  </ul>\n"
	set current_level [expr $current_level - 1]
    }	
    append projects_html "<li>
	<a href=../projects/view?project_id=$project_id>$project_nr</a>: 
	$project_name
    "
    incr ctr
    if {$ctr > $max_projects} { break }
}

if { [exists_and_not_null level] && $llevel < $current_level } {
    append projects_html "  </ul>\n"
}	
if { [empty_string_p $projects_html] } {
    set projects_html "  <li><i>None</i>\n"
}

if {$ctr > $max_projects} {
    append projects_html "<li><A HREF='/intranet/projects/index?customer_id=$customer_id&status_id=0'>more projects...</A>\n"
}

if { $user_admin_p > 0 } {
    append projects_html "  <p><li><a href=../projects/new?customer_id=$customer_id>Add a project</a>"
} 


# ------------------------------------------------------
# Customer Invoices
# ------------------------------------------------------


# Append the list of invoices
if {[im_permission $user_id view_finance]} {
#    append left_column [im_invoice_component $customer_id]
}


# ------------------------------------------------------
# Forum Component
# ------------------------------------------------------

set forum_html ""
if {0} {

    set current_user_id $user_id
    set forum_title_text "<B>Forum Items</B>"
    set forum_title [im_forum_create_bar $forum_title_text $customer_id $return_url]

    # Variables of this page to pass through im_forum_component to maintain the
    # current selection and view of the current project
    set export_var_list [list customer_id forum_start_idx forum_order_by forum_how_many forum_view_name]

    set forum_content [im_forum_component $current_user_id $customer_id $current_url $return_url $export_var_list $forum_view_name $forum_order_by]

    # im_forum_component {user_id customer_id current_page_url return_url export_var_list {view_name "forum_list_short"} {forum_order_by "priority"} {restrict_to_mine_p f} {restrict_to_topic_type_id 0} {restrict_to_topic_status_id 0} {restrict_to_asignee_id 0} {max_entries_per_page 0} {start_idx 1} }

    set forum_html [im_table_with_title $forum_title $forum_content]
}


set company_members [im_group_member_component $customer_id $user_id $user_admin_p $return_url [im_employee_group_id]]

set enable_project_estimates 0
set also_add_to_group [im_customer_group_id]
set customer_members [im_group_member_component $customer_id $user_id $user_admin_p $return_url [im_customer_group_id] [im_employee_group_id] $also_add_to_group]



set projects_html [im_table_with_title "Projects" $projects_html]
set company_members_html [im_table_with_title "Employees" $company_members]
set customer_members_html [im_table_with_title "Client Contacts" $customer_members]



