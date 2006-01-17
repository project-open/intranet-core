# /packages/intranet-core/www/admin/cleanup-demo/cleanup-companies.tcl
#
# Copyright (C) 2004 Company/Open
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

    @author frank.bergmann@company-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [ad_conn url] }

set page_title "[_ intranet-core.Nuke_Demo_Companies]"
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action "all"
set action_list [list "[_ intranet-core.Nuke_All_Demo_Companies]" "[export_vars -base "cleanup-companies-2" {return_url action}]" "[_ intranet-core.Nuke_All_Demo_Companies]"]
set action_list {}

set elements_list {
  company_id {
    label "[_ intranet-core.Id]"
  }
  company_nr {
    label "[_ intranet-core.Company_Nr]"
    display_template {
	    <a href="@companies.company_url@">@companies.company_nr@</a>
    }
  }
  company_name {
    label "[_ intranet-core.Name]"
    display_template {
	    <a href="@companies.company_url@">@companies.company_name@</a>
    }
  }
  company_type {
  	label "[_ intranet-core.Company_Type]"
  }
  company_status {
  	label "[_ intranet-core.Company_Status]"
  }
}

list::create \
        -name company_list \
        -multirow companies \
        -key company_id \
        -actions $action_list \
        -elements $elements_list \
	-bulk_actions [list [_ intranet-core.Nuke_Checked_Companies] cleanup-companies-2 [_ intranet-core.Nuke_Checked_Companies]] \
	-bulk_action_export_vars { return_url } \
        -bulk_action_method post \
        -filters {
        	return_url
        }
        
db_multirow -extend {company_url} companies get_companies "
	select
	 	c.*,
		im_category_from_id(c.company_status_id) as company_status,
		im_category_from_id(c.company_type_id) as company_type,
		c.company_path as company_nr
	from
		im_companies c
	where
		1=1
	order by 
		c.company_id
" {
	set company_url [export_vars -base "/intranet/companies/view" {company_id return_url}]
}

