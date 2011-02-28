# /packages/intranet-core/www/intranet/companies/view.tcl
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
    View all info regarding one company

    @param company_id the company_id of this company

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)

} {
    { company_id:integer 0}
    { object_id:integer 0}
    { forum_order_by "" }
    show_all_correspondance_comments:integer,optional
}

# -----------------------------------------------------------
# Defaults & Security
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $user_id]

set return_url [im_url_with_query]
set current_url [ns_conn url]
set context_bar [im_context_bar [list ./ "[_ intranet-core.Companies]"] "[_ intranet-core.One_company]"]
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

if {0 == $company_id} {set company_id $object_id}
if {0 == $company_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_specify_a_1]"
    return
}

# Check permissions. "See details" is an additional check for
# critical information
im_company_permissions $user_id $company_id view read write admin
set see_details $read
set see_sales_details $admin

if {!$read} {
    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
    <li>[_ intranet-core.lt_You_dont_have_suffici_2]"
    return
}

# Should we bother about State and ZIP fields?
set some_american_readers_p [parameter::get_from_package_key -package_key acs-subsite -parameter SomeAmericanReadersP -default 0]


# Check if the invoices was changed outside of ]po[...
im_audit -object_type "im_company" -object_id $company_id -action before_view


# -----------------------------------------------------------
# Get everything about the company
# -----------------------------------------------------------


set extra_selects [list "0 as zero"]
set column_sql "
        select  w.deref_plpgsql_function,
		aa.attribute_name,
		aa.table_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_company'
"
db_foreach column_list_sql $column_sql {
    switch $table_name {
	"im_companies" { set attribute_table "c." }
	"im_offices" { set attribute_table "o." }
	default { set attribute_table "" }
    }
    lappend extra_selects "${deref_plpgsql_function}(${attribute_table}${attribute_name}) as ${attribute_name}_deref"
}
set extra_select [join $extra_selects ",\n\t"]


db_1row company_get_info "
select 
	c.*,
	im_name_from_user_id(c.primary_contact_id) as primary_contact_name,
	im_email_from_user_id(c.primary_contact_id) as primary_contact_email,
	im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
	im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
	im_name_from_user_id(c.manager_id) as manager,
	im_category_from_id(c.company_status_id) as company_status,
	im_category_from_id(c.company_type_id) as company_type,
	im_category_from_id(c.annual_revenue_id) as annual_revenue,
	to_char(start_date,'Month DD, YYYY') as start_date, 
        o.phone,
        o.fax,
        o.address_line1,
        o.address_line2,
        o.address_city,
        o.address_state,
        o.address_postal_code,
        o.address_country_code,
	$extra_select
from 
	im_companies c,
        im_offices o
where 
        c.company_id = :company_id
	and c.main_office_id = o.office_id
"

set country_name [db_string company_get_cc "select cc.country_name from country_codes cc where cc.iso = :address_country_code" -default ""]

set page_title $company_name
set left_column ""

append left_column "
  <tr class=rowodd><td>[_ intranet-core.Name]</td><td>$company_name</td></tr>
  <tr class=roweven><td>[_ intranet-core.Path]</td><td>$company_path</td></tr>
  <tr class=rowodd><td>[_ intranet-core.Status]</td><td>$company_status</td></tr>"

if {$see_details} {
    append left_column "
  <tr class=roweven><td>[_ intranet-core.Client_Type]</td><td>$company_type</td></tr>
  <tr class=rowodd><td>[_ intranet-core.Key_Account]</td><td><a href=[im_url_stub]/users/view?user_id=$manager_id>$manager</a></td></tr>
    "
}

set state_column ""
if {$some_american_readers_p} { set state_column "
  <tr class=rowodd><td>[_ intranet-core.State]</td><td>$address_state</td></tr>\n"
}

if {$see_details} {
    append left_column "
  <tr class=rowodd><td>[_ intranet-core.Phone]</td><td>$phone</td></tr>
  <tr class=roweven><td>[_ intranet-core.Fax]</td><td>$fax</td></tr>
  <tr class=rowodd><td>[_ intranet-core.Address1]</td><td>$address_line1</td></tr>
  <tr class=roweven><td>[_ intranet-core.Address2]</td><td>$address_line2</td></tr>
  <tr class=rowodd><td>[_ intranet-core.City]</td><td>$address_city</td></tr>
  $state_column
  <tr class=roweven><td>[_ intranet-core.Postal_Code]</td><td>$address_postal_code</td></tr>
  <tr class=rowodd><td>[_ intranet-core.Country]</td><td>$country_name</td></tr>
    "

    if {![empty_string_p $site_concept]} {
	# Add a "http://" before the web site if it starts with "www."...
	if {[regexp {www\.} $site_concept]} { set site_concept "http://$site_concept" }
	append left_column "<tr class=roweven><td>[_ intranet-core.Web_Site]</td><td><A HREF=\"$site_concept\">$site_concept</A></td></tr>\n"

    }

    append left_column "<tr class=rowodd><td>[_ intranet-core.VAT_Number]</td><td>$vat_number</td></tr>\n"

# ------------------------------------------------------
# Primary Contact
# ------------------------------------------------------

    set primary_contact_text ""
    set limit_to_users_in_group_id [im_employee_group_id]
    if { [empty_string_p $primary_contact_id] } {
	
	if { $admin } {
	    set primary_contact_text "<a href=primary-contact?[export_url_vars company_id limit_to_users_in_group_id]>Add primary contact</a>\n"
	} else {
	    set primary_contact_text "<i>[_ intranet-core.none]</i>"
	}
    
    } else {
	
	append primary_contact_text "<a href=/intranet/users/view?user_id=$primary_contact_id>$primary_contact_name</a>"
    
	if { $admin } {
	    append primary_contact_text "
	(<a href=primary-contact?[export_url_vars company_id limit_to_users_in_group_id]>[im_gif turn "Change the primary contact"]</a> | <a href=primary-contact-delete?[export_url_vars company_id return_url]>[im_gif delete "Delete the primary contact"]</a>)\n"
	}
    }

    append left_column "<tr class=roweven><td>[_ intranet-core.Primary_contact]</td><td>$primary_contact_text</td></tr>"


# ------------------------------------------------------
# Accounting Contact
# ------------------------------------------------------

    set accounting_contact_text ""
    set limit_to_users_in_group_id [im_employee_group_id]
    if { [empty_string_p $accounting_contact_id] } {
	
	if { $admin } {
	    set accounting_contact_text "<a href=accounting-contact?[export_url_vars company_id limit_to_users_in_group_id]>[_ intranet-core.lt_Add_accounting_contac]</a>\n"
	} else {
	    set accounting_contact_text "<i>[_ intranet-core.none]</i>"
	}
	
    } else {
	
	append accounting_contact_text "<a href=/intranet/users/view?user_id=$accounting_contact_id>$accounting_contact_name</a>"
	if { $admin } {
	    append accounting_contact_text "    (<a href=accounting-contact?[export_url_vars company_id limit_to_users_in_group_id]>[im_gif turn "Change the accounting contact"]</a> | <a href=accounting-contact-delete?[export_url_vars company_id return_url]>[im_gif delete "Delete the accounting contact"]</a>)\n"
	}
    }
    
    append left_column "<tr class=rowodd><td>[_ intranet-core.Accounting_contact]</td><td>$accounting_contact_text</td></tr>"
    append left_column "<tr class=roweven><td>[_ intranet-core.Start_Date]</td><td>$start_date</td></tr>\n"

    set ctr 1

# ------------------------------------------------------
# Continuation ...
# ------------------------------------------------------

    if { ![empty_string_p $note] } {
	append left_column "<tr $bgcolor([expr $ctr%2])><td>[_ intranet-core.Notes]</td><td><font size=-1>$note</font>\n</td></tr>\n"
	incr ctr
    }

# ------------------------------------------------------
# Add DynField Columns to the display
# ------------------------------------------------------

    set column_sql "
	select
		aa.pretty_name,
		aa.attribute_name
	from
		im_dynfield_widgets w,
		acs_attributes aa,
		im_dynfield_attributes a
		LEFT OUTER JOIN (
			select *
			from im_dynfield_layout
			where page_url = ''
		) la ON (a.attribute_id = la.attribute_id)
	where
		a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_company' and
		(a.also_hard_coded_p is NULL or a.also_hard_coded_p = 'f')
	order by
		coalesce(la.pos_y,0), coalesce(la.pos_x,0)
    "
    db_foreach column_list_sql $column_sql {
	set var ${attribute_name}_deref
	set value [expr $$var]
	if {"" != [string trim $value]} {
	    append left_column "
		  <tr $bgcolor([expr $ctr%2])>
		    <td>[lang::message::lookup "" intranet-core.$attribute_name $pretty_name]</td>
		    <td>$value</td>
		  </tr>
	    "
	    incr ctr
	}
    }

}


# ------------------------------------------------------
# 
# ------------------------------------------------------

set left_column_action ""
if {$admin} {
    set left_column_action "
	<tr><td>&nbsp;</td><td>
	<form action=new method=POST>
	[export_form_vars company_id return_url]
	<input type=submit value='[_ intranet-core.Edit]'>
	</form></td></tr>"
}


# ------------------------------------------------------
# Company Project List
# ------------------------------------------------------

set sql "
	select
		p.*,
		1 as llevel
	from
		im_projects p
	where 
		p.company_id = :company_id
	        and p.parent_id is null
		and p.project_status_id not in (
			[im_project_status_canceled], 
			[im_project_status_deleted]
		)
		and p.project_type_id not in (
			[im_project_type_task], 
			[im_project_type_ticket]
		)
		
	order by p.project_nr DESC
"

set projects_html ""
set current_level 1
set ctr 1
set max_projects 15
db_foreach company_list_active_projects $sql  {
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
    set projects_html "  <li><i>[_ intranet-core.None]</i>\n"
}

if {$ctr > $max_projects} {
    append projects_html "<li><A HREF='/intranet/projects/index?company_id=$company_id&status_id=0'>[_ intranet-core.more_projects]</A>\n"
}

if { $admin > 0 } {
    append projects_html "  <p><li><a href=../projects/new?company_id=$company_id>[_ intranet-core.Add_a_project]</a>"
} 



# ------------------------------------------------------
# Components
# ------------------------------------------------------


set company_members [im_group_member_component $company_id $user_id $admin $return_url [im_employee_group_id]]

if {!$user_is_employee_p} { set company_members "" }

set enable_project_estimates 0
set also_add_to_group [im_customer_group_id]
set company_clients [im_group_member_component $company_id $user_id $admin $return_url "" [im_employee_group_id] $also_add_to_group]



set projects_html [im_table_with_title "[_ intranet-core.Projects]" "<ul>$projects_html</ul>"]

set our_employees_str [lang::message::lookup "" intranet-core.Our_employees_related "Our Employees (managing the company)"]
set companys_employees_str [lang::message::lookup "" intranet-core.Companys_Contacts "Company's Contacts"]

# ad_return_complaint 1 $company_members
set company_members_html [im_table_with_title $our_employees_str $company_members]
# ad_return_complaint 1 $company_members_html
set company_clients_html [im_table_with_title $companys_employees_str $company_clients]



