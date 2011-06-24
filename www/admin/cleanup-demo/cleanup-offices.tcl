# /packages/intranet-core/www/admin/cleanup-demo/cleanup-offices.tcl
#
# Copyright (C) 2004 Office/Open
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
    Duke demo offices
    @author frank.bergmann@office-open.com
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

set page_title [lang::message::lookup "" intranet-core.Nuke_Demo_Offices "Nuke Demo Offices"]
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action "all"
set action_list {}


set elements_list {
  office_id {
    label "[lang::message::lookup {} intranet-core.Id]"
  }
  office_path {
      label "[lang::message::lookup {} intranet-core.Office_Path {Office Path}]"
    display_template {
	    <a href="@offices.office_url@">@offices.office_path@</a>
    }
  }
  office_name {
    label "[lang::message::lookup {} intranet-core.Name]"
    display_template {
	    <a href="@offices.office_url@">@offices.office_name@</a>
    }
  }
  num_companies {
  	label "Num Companies"
  }
  office_type {
  	label "[lang::message::lookup {} intranet-core.Office_Type]"
  }
  office_status {
  	label "[lang::message::lookup {} intranet-core.Office_Status]"
  }
}

list::create \
        -name office_list \
        -multirow offices \
        -key office_id \
        -actions $action_list \
        -elements $elements_list \
    -bulk_actions [list [lang::message::lookup {} intranet-core.Nuke_Checked_Offices {Nuke Checked Offices}] cleanup-offices-2 [lang::message::lookup {} intranet-core.Nuke_Checked_Offices {Nuke Checked Offices}]] \
	-bulk_action_export_vars { return_url } \
        -bulk_action_method post \
        -filters {
        	return_url
        }
        
db_multirow -extend {office_url} offices get_offices "
	select
	 	o.*,
		im_category_from_id(o.office_status_id) as office_status,
		im_category_from_id(o.office_type_id) as office_type,
		num_offices.cnt as num_companies
	from
		im_offices o
		LEFT OUTER JOIN (
			select	count(*) as cnt,
				oo.office_id
			from	im_offices oo,
				im_companies c
			where	oo.company_id = c.company_id
			group by oo.office_id
		) num_offices ON (o.office_id = num_offices.office_id)
	where
		1=1
	order by 
		o.office_id DESC
" {
	set office_url [export_vars -base "/intranet/offices/view" {office_id return_url}]
}

