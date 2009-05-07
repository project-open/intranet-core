# /packages/intranet-core/www/admin/views/index.tcl
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

    @author juanjoruizx@yahoo.es
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

if {"" == $return_url} { set return_url [im_url_with_query] }

set page_title "[_ intranet-core.Manage_Views]"
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action_list [list "[_ intranet-core.Add_new_View]" "[export_vars -base "new" {return_url}]" "[_ intranet-core.Add_new_View]"]

set elements_list {
  view_id {
    label "[_ intranet-core.View_Id]"
  }
  view_name {
    label "[_ intranet-core.View_Name]"
    display_template {
	    <a href="@views.view_url@">@views.view_name@</a>
    }
  }
  view_type {
  	label "[_ intranet-core.View_Type]"
  }
  view_status {
  	label "[_ intranet-core.View_Status]"
  }
  sort_order {
	label "[_ intranet-core.Sort_Order]"
  }
  
}

list::create \
        -name view_list \
        -multirow views \
        -key view_id \
        -actions $action_list \
        -elements $elements_list \
        -filters {
        	return_url
        }
        
db_multirow -extend {view_url} views get_views "" {
	set view_url [export_vars -base "new" {view_id return_url}]
}